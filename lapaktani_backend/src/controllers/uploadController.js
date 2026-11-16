const uploadCategorizedFile = (category = 'products') => async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Tidak ada file yang diunggah. Pastikan field berformat multipart/form-data dengan nama field "image", "file", atau "document".'
      });
    }

    const protocol = req.protocol;
    const host = req.get('host');
    const cleanCategory = ['products', 'ktp', 'docs', 'soil'].includes(category) ? category : 'products';
    const relativeUrl = `/uploads/${cleanCategory}/${req.file.filename}`;
    const publicUrl = `${protocol}://${host}${relativeUrl}`;

    return res.status(200).json({
      success: true,
      message: `File kategori ${cleanCategory} berhasil diunggah dengan verifikasi magic bytes.`,
      data: {
        category: cleanCategory,
        filename: req.file.filename,
        url: publicUrl,
        image_url: publicUrl,
        relative_url: relativeUrl,
        size: req.file.size,
        mimetype: req.file.mimetype
      }
    });
  } catch (error) {
    console.error('[UPLOAD] Error processing upload:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Gagal memproses unggahan file.'
    });
  }
};

const uploadProductImage = uploadCategorizedFile('products');

module.exports = {
  uploadProductImage,
  uploadCategorizedFile
};
