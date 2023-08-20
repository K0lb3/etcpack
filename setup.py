import os
from setuptools import Extension, setup

from Cython.Build import cythonize


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
extensions = cythonize(extensions)

setup(ext_modules=extensions)
