# TODO:

Here are some features/fixes/etc. I expect to get to eventually. I would also welcome external
contributions for these if you're interested.

1. Gradient slider for color biases. This is particularly useful for the current Perlin noise
   method, since its distribution rarely goes into the lower- or upper-third of its range.
   This should also allow colors to be rearranged which is currently unsupported without changing
   their order in the palette itself.
2. Preview options. Preview option on the whole canvas could prove to be too slow, so probably
   a tiny canvas in the dialog menu itself, maybe just `16x16`.
3. Cached method + method options. When applying the same method repeatedly it gets annoying having
   to set the same settings again and again. Preserving settings at least for the length of the
   aseprite session would be good.
