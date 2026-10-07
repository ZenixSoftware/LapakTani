const uploadProductImage = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Tidak ada file gambar yang diunggah. Pastikan field berformat multipart/form-data dengan nama field "image" atau "file".'
      });
    }

    const protocol = req.protocol;
    const host = req.get('host');
    const relativeUrl = `/uploads/products/${req.file.filename}`;
    const publicUrl = `${protocol}://${host}${relativeUrl}`;

    return res.status(200).json({
      success: true,
      message: 'Foto produk berhasil diunggah.',
      data: {
        filename: req.file.filename,
        image_url: publicUrl,
        relative_url: relativeUrl,
        size: req.file.size,
        mimetype: req.file.mimetype
      }
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal memproses unggahan foto produk.',
      error: error.message
    });
  }
};

module.exports = {
  uploadProductImage
};
