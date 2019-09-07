typedef unsigned char uint8;
typedef unsigned short uint16;
typedef short int16;

void setupAlphaTable();
void decompressBlockAlphaC(uint8* data, uint8* img, int width, int height, int ix, int iy, int channels);
void decompressBlockETC21BitAlphaC(unsigned int block_part1, unsigned int block_part2, uint8 *img, uint8* alphaimg, int width, int height, int startx, int starty, int channelsRGB);
void decompressBlockETC2c(unsigned int block_part1, unsigned int block_part2, uint8 *img, int width, int height, int startx, int starty, int channels);
bool readCompressParams(void);
void setupAlphaTableAndValtab();
void decompressBlockAlpha(uint8* data, uint8* img, int width, int height, int ix, int iy);
void decompressBlockAlphaC(uint8* data, uint8* img, int width, int height, int ix, int iy, int channels);
void decompressBlockETC21BitAlpha(unsigned int block_part1, unsigned int block_part2, uint8 *img, uint8* alphaimg, int width, int height, int startx, int starty);
void decompressBlockETC2(unsigned int block_part1, unsigned int block_part2, uint8 *img, int width, int height, int startx, int starty);
void decompressBlockAlpha16bit(uint8* data, uint8* img, int width, int height, int ix, int iy);