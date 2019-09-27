from PIL import Image, ImageFile
from io import BytesIO, BufferedReader
import struct
from libc.stdlib cimport malloc, free
from etcpack cimport *

cdef unsigned int read_big_endian4byte_word(f : BytesIO):
	s = struct.unpack("BBBB", f.read(4))
	return (s[0] << 24) | (s[1] << 16) | (s[2] << 8) | s[3]


class ETC2Decoder(ImageFile.PyDecoder):
	dstChannelBytes = 1
	dstChannels = 3
	
	def decode(self, buffer):
		self.set_as_raw(self._unpack_etc(buffer, self.args[0], self.state.xsize, self.state.ysize))
		return -1, 0
	
	def _unpack_etc(self, data, format_py : int, active_width : int, active_height : int) -> bytes:
		if isinstance(data, (bytes, bytearray)):
			f = BytesIO(data)
		elif isinstance(data, (BytesIO, BufferedReader)):
			f = data
		else:
			raise TypeError("ETC2Decoder - invalid data input of type %s" % type(data))
		
		# later used to save some position calculations -> y * height + x
		cdef unsigned int pos
		# later used for the actual read operations as buffer
		cdef unsigned int block_part1, block_part2
		# cuz python doesn't like py_int in [ cint]
		cdef int format_c = format_py
		# ktx file style
		cdef int width = <int> int((active_width + 3) / 4) * 4
		cdef int height = <int> int((active_height + 3) / 4) * 4
		
		# init image buffer
		bimg = b''
		balphaimg = b''
		bnewimg = b''
		cdef uint8*img
		cdef uint8*alphaimg
		cdef uint8*alphaimg2
		cdef uint8*newimg
		cdef uint8*newalphaimg
		cdef uint8 alphablock[8]
		
		# Load table
		readCompressParams()
		
		#print("Width = %d, Height = %d\n" % (width, height))
		#print("active pixel area: top left %d x %d area.\n" % (active_width, active_height))
		
		if format_c == ETC2PACKAGE_RG_NO_MIPMAPS:
			bimg = bytes(3 * width * height * 2)
			img = <uint8*> bimg  #<uint8*>malloc(3*width*height*2)
		else:
			bimg = bytes(3 * width * height)
			img = <uint8*> bimg  #<uint8*>malloc(3*width*height)
		
		if format_c in [
			ETC2PACKAGE_RGBA_NO_MIPMAPS,
			ETC2PACKAGE_R_NO_MIPMAPS,
			ETC2PACKAGE_RG_NO_MIPMAPS,
			ETC2PACKAGE_RGBA1_NO_MIPMAPS,
			ETC2PACKAGE_sRGBA_NO_MIPMAPS,
			ETC2PACKAGE_sRGBA1_NO_MIPMAPS
		]:
			#printf("alpha channel decompression\n")
			self.dstChannels = 4
			balphaimg = bytes(width * height * 2)
			alphaimg = <uint8*> balphaimg  #malloc(width*height*2)
			setupAlphaTableAndValtab()
		
		if format_c == ETC2PACKAGE_RG_NO_MIPMAPS:
			balphaimg2 = bytes(width * height * 2)
			alphaimg2 = <uint8*> balphaimg2  #malloc(width*height*2)
		
		for y in range(height // 4):
			for x in range(width // 4):
				#decode alpha channel for RGBA
				if format_c == ETC2PACKAGE_RGBA_NO_MIPMAPS or format_c == ETC2PACKAGE_sRGBA_NO_MIPMAPS:
					alpha_block = f.read(8)
					alphablock = <uint8*> alpha_block
					#fread(alphablock,1,8,f)
					decompressBlockAlpha(alphablock, alphaimg, width, height, 4 * x, 4 * y)
				
				#color channels for most normal modes
				if format_c != ETC2PACKAGE_R_NO_MIPMAPS and format_c != ETC2PACKAGE_RG_NO_MIPMAPS:
					#we have normal ETC2 color channels, decompress these
					block_part1 = read_big_endian4byte_word(f)
					block_part2 = read_big_endian4byte_word(f)
					#read_big_endian_4byte_word(&block_part1,f)
					#read_big_endian_4byte_word(&block_part2,f)
					if format_c == ETC2PACKAGE_RGBA1_NO_MIPMAPS or format_c == ETC2PACKAGE_sRGBA1_NO_MIPMAPS:
						decompressBlockETC21BitAlpha(block_part1, block_part2, img, alphaimg, width, height, 4 * x,
						                             4 * y)
					else:
						decompressBlockETC2(block_part1, block_part2, img, width, height, 4 * x, 4 * y)
				
				#one or two 11-bit alpha channels for R or RG.
				if format_c == ETC2PACKAGE_R_NO_MIPMAPS or format_c == ETC2PACKAGE_RG_NO_MIPMAPS:
					alpha_block = f.read(8)
					alphablock = <uint8*> alpha_block
					#fread(alphablock,1,8,f)
					decompressBlockAlpha16bit(alphablock, alphaimg, width, height, 4 * x, 4 * y)
				
				if format_c == ETC2PACKAGE_RG_NO_MIPMAPS:
					alpha_block = f.read(8)
					alphablock = <uint8*> alpha_block
					#fread(alphablock,1,8,f)
					decompressBlockAlpha16bit(alphablock, alphaimg2, width, height, 4 * x, 4 * y)
		
		if format_c == ETC2PACKAGE_RG_NO_MIPMAPS:
			for y in range(height):
				for x in range(width):
					pos = y * width + x
					img[6 * pos] = alphaimg[2 * pos]
					img[6 * pos + 1] = alphaimg[2 * pos + 1]
					img[6 * pos + 2] = alphaimg2[2 * pos]
					img[6 * pos + 3] = alphaimg2[2 * pos + 1]
					img[6 * pos + 4] = 0
					img[6 * pos + 5] = 0
		
		# Ok, and now only write out the active pixels to the .ppm file.
		# (But only if the active pixels differ from the total pixels)
		
		if height != <int> active_height or width != <int> active_width:
			if format_c == ETC2PACKAGE_RG_NO_MIPMAPS:
				newimg = <uint8*> malloc(3 * active_width * active_height * 2)
			else:
				newimg = <uint8*> malloc(3 * active_width * active_height)
			
			if format_c in [
				ETC2PACKAGE_RGBA_NO_MIPMAPS,
				ETC2PACKAGE_RGBA1_NO_MIPMAPS,
				ETC2PACKAGE_R_NO_MIPMAPS,
				ETC2PACKAGE_sRGBA_NO_MIPMAPS,
				ETC2PACKAGE_sRGBA1_NO_MIPMAPS
			]:
				newalphaimg = <uint8*> malloc(active_width * active_height * 2)
			
			# Convert from total area to active area:
			for yy in range(active_height):
				for xx in range(active_width):
					if format_c != ETC2PACKAGE_R_NO_MIPMAPS and format_c != ETC2PACKAGE_RG_NO_MIPMAPS:
						newimg[(yy * active_width) * 3 + xx * 3 + 0] = img[(yy * width) * 3 + xx * 3 + 0]
						newimg[(yy * active_width) * 3 + xx * 3 + 1] = img[(yy * width) * 3 + xx * 3 + 1]
						newimg[(yy * active_width) * 3 + xx * 3 + 2] = img[(yy * width) * 3 + xx * 3 + 2]
					elif format_c == ETC2PACKAGE_RG_NO_MIPMAPS:
						newimg[(yy * active_width) * 6 + xx * 6 + 0] = img[(yy * width) * 6 + xx * 6 + 0]
						newimg[(yy * active_width) * 6 + xx * 6 + 1] = img[(yy * width) * 6 + xx * 6 + 1]
						newimg[(yy * active_width) * 6 + xx * 6 + 2] = img[(yy * width) * 6 + xx * 6 + 2]
						newimg[(yy * active_width) * 6 + xx * 6 + 3] = img[(yy * width) * 6 + xx * 6 + 3]
						newimg[(yy * active_width) * 6 + xx * 6 + 4] = img[(yy * width) * 6 + xx * 6 + 4]
						newimg[(yy * active_width) * 6 + xx * 6 + 5] = img[(yy * width) * 6 + xx * 6 + 5]
					
					if format_c == ETC2PACKAGE_R_NO_MIPMAPS:
						newalphaimg[((yy * active_width) + xx) * 2] = alphaimg[2 * ((yy * width) + xx)]
						newalphaimg[((yy * active_width) + xx) * 2 + 1] = alphaimg[2 * ((yy * width) + xx) + 1]
					
					if format_c in [
						ETC2PACKAGE_RGBA_NO_MIPMAPS,
						ETC2PACKAGE_RGBA1_NO_MIPMAPS,
						ETC2PACKAGE_sRGBA_NO_MIPMAPS,
						ETC2PACKAGE_sRGBA1_NO_MIPMAPS
					]:
						newalphaimg[((yy * active_width) + xx)] = alphaimg[((yy * width) + xx)]
			
			free(img)
			img = newimg
			if format_c in [
				ETC2PACKAGE_RGBA_NO_MIPMAPS,
				ETC2PACKAGE_RGBA1_NO_MIPMAPS,
				ETC2PACKAGE_R_NO_MIPMAPS,
				ETC2PACKAGE_sRGBA_NO_MIPMAPS,
				ETC2PACKAGE_sRGBA1_NO_MIPMAPS
			]:
				free(alphaimg)
				alphaimg = newalphaimg
			
			if format_c == ETC2PACKAGE_RG_NO_MIPMAPS:
				free(alphaimg)
				free(alphaimg2)
				alphaimg = NULL
				alphaimg2 = NULL
		
		# merge image and alpha channels
		if format_c in [
			ETC2PACKAGE_RGBA_NO_MIPMAPS,
			ETC2PACKAGE_RGBA1_NO_MIPMAPS,
			ETC2PACKAGE_sRGBA_NO_MIPMAPS,
			ETC2PACKAGE_sRGBA1_NO_MIPMAPS
		]:
			bnewimg = bytes(4 * active_width * active_height)
			newimg = <uint8*> bnewimg
			for y in range(active_height):
				for x in range(active_width):
					pos = y * active_width + x
					newimg[4 * pos] = img[3 * pos]
					newimg[4 * pos + 1] = img[3 * pos + 1]
					newimg[4 * pos + 2] = img[3 * pos + 2]
					newimg[4 * pos + 3] = alphaimg[pos]
			return bnewimg
		
		elif format_c == ETC2PACKAGE_R_NO_MIPMAPS:  # not sure if this is the correct solution
			bnewimg = bytes(active_width * active_height)
			newimg = <uint8*> bnewimg
			for y in range(active_height):
				for x in range(active_width):
					pos = y * active_width + x
					newimg[pos] = alphaimg[pos]
			return bnewimg
		
		elif format_c == ETC2PACKAGE_RG_NO_MIPMAPS:
			bnewimg = bytes(3 * active_width * active_height)
			newimg = <uint8*> bnewimg
			for y in range(active_height):
				for x in range(active_width):
					pos = y * active_width + x
					newimg[3 * pos] = img[6 * pos]  #R
					newimg[3 * pos + 1] = img[6 * pos + 1]  #G
			return bnewimg
		
		else:
			return bimg


if 'etc2' not in Image.DECODERS:
	Image.register_decoder('etc2', ETC2Decoder)
