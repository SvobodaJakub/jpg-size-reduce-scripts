# jpg-size-reduce-scripts

BASH scripts for lossy and lossless JPEG size reduction using imagemagick and jpegtran.

**Experimental quality scripts - might eat your data**

## Lossless

`jpegtran-batch-optimize.sh` tries 3 different lossless optimizations and selects the smallest file, or leaves the original if the original is the smallest one.

To recursively process directory structure starting with the current directory (**you will lose the originals!**):

```
find . -type d -exec bash -c 'cd "$1" && pwd && bash /path/to/jpegtran-batch-optimize.sh' _ {} ';'
```

Example output:

```
IMG_8026.JPG: 9 percent saved, 168171 bytes saved, 1789753 -> 1621582
IMG_8027.JPG: 6 percent saved, 342262 bytes saved, 4909055 -> 4566793
IMG_8028.JPG: 6 percent saved, 323360 bytes saved, 4770205 -> 4446845
IMG_8029.JPG: 8 percent saved, 462463 bytes saved, 5660693 -> 5198230
IMG_8030.JPG: 6 percent saved, 341325 bytes saved, 4908218 -> 4566893
IMG_8031.JPG: 6 percent saved, 330306 bytes saved, 4880578 -> 4550272
IMG_8032.JPG: 5 percent saved, 207419 bytes saved, 3935012 -> 3727593
IMG_8033.JPG: 5 percent saved, 206448 bytes saved, 3903478 -> 3697030
IMG_8034.JPG: 5 percent saved, 232966 bytes saved, 4150738 -> 3917772
IMG_8067.JPG: no change
total bytes orig: 43306370
total bytes saved: 2614720
total MiB orig: 41.30
total MiB saved: 2.49
percent saved: 6.0
```

## Lossy

The `jpg-quality-reducer-*.sh` scripts do lossy compression on the files. I created each to serve my specific needs:

* jpg-quality-reducer-hiquality - high-quality photos that made it to nearly to the final selection and I still want to keep them without noticeable loss (noticeable to me when comparing by switching between the original and compressed versions zoomed to 150%)
    * takes about 50% of the original size
* jpg-quality-reducer-standard - photos that didn't make it to any of the selections and I might decide to throw them away a few years later; very little noticeable loss
    * takes about 40% of the original size
* jpg-quality-reducer-lowquality - heavily compressed photos that are mostly ok when viewed on a laptop screen without zoom, for sharing informative-quality photos over email, and for hoarding informative-quality reference photos in mobile phone (when used as photo memos, e.g. of doctor's office hours, etc.)
    * takes about 10%-30% of the original size
* jpg-quality-reducer-strip-web-2048-85.sh - photos that look not too compressed on a laptop screen, but are not good for zooming; strips metadata
* in the mozjpeg folder, there are alternative versions of the scripts that use the mozjpeg encoder
    * jpg-quality-reducer-lowquality and jpg-quality-reducer-standard - similar filesize than using the scripts from the parent dir, but higher quality
    * jpg-quality-reducer-lowquality-slightly-better - sth in between lowquality and standard, I found it useful just once
    * jpg-quality-reducer-lowquality-4800-adaptive - Heavily compressed photos that are mostly ok when viewed on a large screen without zoom. It uses an extremely rudimentary ad-hoc psychovisual model: Photos that contain mostly smooth gradients are compressed with higher quality than photos that contain mostly edges or noise, because I'm more sensitive to blockiness in gradients when that's the majority of the photo, than blockiness in small patches of gradients when the photo is mostly edges, and because I'm more sensitive to artifacts on edges when there's only a few of them (imagine a small sharp object in focus with large blurred background), than when the full photo is edges (imagine a forest). I use this to back up my photos on a low-capacity USB flash drive.

The scripts use a quantization table from imagemagick forums.

Note: The quality percentages mean nothing and are useless for comparisons, as the results depend both on the software (IM vs. mozjpeg) and the quantization tables (baseline vs mozjpeg MS-SSIM vs the one from IM's repo by Dr. Nicolas Robidoux).

To recursively process directory structure starting with the current directory (**you will lose the originals!**):

```
find . -type d -exec bash -c 'cd "$1" && pwd && bash /path/to/jpg-quality-reducer-script.sh' _ {} ';'
```

It is worth trying to follow a lossy compression by the lossless optimization.

