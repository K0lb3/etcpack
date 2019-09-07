from libcpp cimport bool

cdef enum ETC_Format:
	ETC1_RGB_NO_MIPMAPS = 0  # RGB
	ETC2PACKAGE_RGB_NO_MIPMAPS = 1  # RGB
	ETC2PACKAGE_RGBA_NO_MIPMAPS_OLD = 2  # RGBA
	ETC2PACKAGE_RGBA_NO_MIPMAPS = 3  # RGBA
	ETC2PACKAGE_RGBA1_NO_MIPMAPS = 4  # RGBA
	ETC2PACKAGE_R_NO_MIPMAPS = 5  # R/A
	ETC2PACKAGE_RG_NO_MIPMAPS = 6  # RGB565
	ETC2PACKAGE_R_SIGNED_NO_MIPMAPS = 7  #
	ETC2PACKAGE_RG_SIGNED_NO_MIPMAPS = 8  #
	ETC2PACKAGE_sRGB_NO_MIPMAPS = 9  # RGB
	ETC2PACKAGE_sRGBA_NO_MIPMAPS = 10  # RGBA
	ETC2PACKAGE_sRGBA1_NO_MIPMAPS = 11  # RGBA

cdef extern from "etcpack.h":
	ctypedef unsigned char uint8
	ctypedef unsigned short uint16
	ctypedef short int16
	
	cdef void setupAlphaTable()
	cdef void decompressBlockAlphaC(uint8*data, uint8*img, int width, int height, int ix, int iy, int channels)
	cdef void decompressBlockETC21BitAlphaC(unsigned int block_part1, unsigned int block_part2, uint8 *img,
	                                        uint8*alphaimg,
	                                        int width, int height, int startx, int starty, int channelsRGB)
	cdef void decompressBlockETC2c(unsigned int block_part1, unsigned int block_part2, uint8 *img, int width,
	                               int height,
	                               int startx, int starty, int channels)
	cdef bool readCompressParams()
	cdef void setupAlphaTableAndValtab()
	cdef void decompressBlockAlphaC(uint8*data, uint8*img, int width, int height, int ix, int iy, int channels)
	cdef void decompressBlockETC21BitAlphaC(unsigned int block_part1, unsigned int block_part2, uint8 *img,
	                                        uint8*alphaimg,
	                                        int width, int height, int startx, int starty, int channelsRGB)
	cdef void decompressBlockETC2(unsigned int block_part1, unsigned int block_part2, uint8 *img, int width, int height,
	                              int startx, int starty)
	cdef void decompressBlockAlpha16bit(uint8*data, uint8*img, int width, int height, int ix, int iy)
	cdef void decompressBlockAlpha(uint8*data, uint8*img, int width, int height, int ix, int iy)
	cdef void decompressBlockETC21BitAlpha(unsigned int block_part1, unsigned int block_part2, uint8 *img,
	                                       uint8*alphaimg,
	                                       int width, int height, int startx, int starty)
