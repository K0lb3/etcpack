import os
from setuptools import Extension, setup

try:
    from Cython.Build import cythonize
except ImportError:
    cythonize = None


def ALL_C(folder, exclude=[]):
    return [
        '/'.join([folder, f])
        for f in os.listdir(folder)
        if f.endswith('.cxx') and f not in exclude
    ]


extensions = [
    Extension(
        name="etcpack",
        sources=[
            "etcpack.pyx",
            *ALL_C('etcpack/source'),
        ],
        language="c++",
        include_dirs=[
            "etcpack/source",
        ],
    )
]
if cythonize:
    extensions = cythonize(extensions)

setup(ext_modules=extensions)
