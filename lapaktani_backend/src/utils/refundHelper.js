const { v4: uuidv4 } = require('uuid');

/**
 * Compute Capped Hybrid Cancellation Fee:
 * - BUYER cancels: fee = min(Rp 50.000, max(Rp 10.000, round(gross * 2%)))
 * - SELLER cancels: fee = 0 (100% full refund)
 */
function calculateHybridRefundFee(grossAmount, cancelledBy = 'BUYER') {
  const gross = Math.max(0, Math.round(Number(grossAmount) || 0));
  const actor = String(cancelledBy || 'BUYER').toUpperCase() === 'SELLER' ? 'SELLER' : 'BUYER';

  if (gross <= 0) {
    return { cancelledBy: actor, grossAmount: 0, feeCharged: 0, refundedAmount: 0, feeFormula: 'NONE' };
  }

  if (actor === 'SELLER') {
    return {
      cancelledBy: 'SELLER',
      grossAmount: gross,
      feeCharged: 0,
      refundedAmount: gross,
      feeFormula: '100% Full Refund (Pembatalan Penjual)'
    };
  }

  const rawTwoPercent = Math.round(gross * 0.02);
  const feeCharged = Math.min(gross, Math.min(50000, Math.max(10000, rawTwoPercent)));
  const refundedAmount = Math.max(0, gross - feeCharged);

  return {
    cancelledBy: 'BUYER',
    grossAmount: gross,
    feeCharged,
    refundedAmount,
    feeFormula: 'min(Rp 50.000, max(Rp 10.000, 2% * Total))'
  };
}

/**
 * Record cancellation refund & platform fee entry into platform_fee_ledger.
 */
async function recordPlatformFeeLedger(connection, {
  refId,
  refType = 'ORDER',
  userId,
  cancelledBy = 'BUYER',
  grossAmount,
  feeCharged,
  refundedAmount,
  reason = ''
}) {
  const id = `fee-${uuidv4().slice(0, 10)}`;
  await connection.query(
    `INSERT INTO platform_fee_ledger
     (id, order_or_bid_id, ref_type, cancelled_by_user_id, cancelled_by_role, gross_amount, fee_charged, refunded_amount, reason)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      id,
      String(refId),
      refType === 'B2B_BID' ? 'B2B_BID' : 'ORDER',
      String(userId),
      cancelledBy === 'SELLER' ? 'SELLER' : 'BUYER',
      grossAmount,
      feeCharged,
      refundedAmount,
      reason ? String(reason).trim() : null
    ]
  );
  return id;
}

module.exports = {
  calculateHybridRefundFee,
  recordPlatformFeeLedger
};
