# etcpack (for python)
A cython wrapper for [etcpack](https://github.com/Ericsson/ETCPACK.git) that integrates etcpack into Pillow as codec.

Install via
``python setup.py install``
- Cython is required

## usage example
```python
from PIL import Image
import etcpack 
#needs to be imported once in the active code, so that the codec can register itself


raw_etc_image_data : bytes
mode = 'RGB'/'RGBA' # depending on the ETC mode
args = (x, ) # x depending on the ETC mode
img = Image.frombytes(mode, size, raw_etc_image_data, 'etc2', args)
```

## codec table
|ETC mode | arg | mode |
|---|---|---|
| ETC1_RGB_NO_MIPMAPS | 0 | RGB |
| ETC2PACKAGE_RGB_NO_MIPMAPS | 1 | RGB |
| ETC2PACKAGE_RGBA_NO_MIPMAPS_OLD | 2 | RGBA | 
| ETC2PACKAGE_RGBA_NO_MIPMAPS | 3 | RGBA |
| ETC2PACKAGE_RGBA1_NO_MIPMAPS | 4 | RGBA |
| ETC2PACKAGE_R_NO_MIPMAPS | 5 | R or A |
| ETC2PACKAGE_RG_NO_MIPMAPS | 6 | RGA | 
| ETC2PACKAGE_R_SIGNED_NO_MIPMAPS | 7 | R or A |
| ETC2PACKAGE_RG_SIGNED_NO_MIPMAPS | 8 | RGA |
| ETC2PACKAGE_sRGB_NO_MIPMAPS | 9 | RGB |
| ETC2PACKAGE_sRGBA_NO_MIPMAPS | 10 | RGBA | 
| ETC2PACKAGE_sRGBA1_NO_MIPMAPS | 11 | RGBA  |

## notes
* compression isn't implemented
* RG is untested
