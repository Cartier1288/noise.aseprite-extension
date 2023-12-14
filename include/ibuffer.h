#pragma once

#include <cstddef>
#include <iterator>
#include <stdexcept>
#include <vector>

#include "vec.h"
#include <functional>

template <typename T, size_t depth> class ibuffer {
public:
  typedef vec<T, depth> pixel;
  typedef long long int pos_t;

  struct iterator {
    using iterator_category = std::forward_iterator_tag;
    using difference_type = std::ptrdiff_t;
    using value_type = pixel;
    using pointer = pixel*;
    using reference = pixel&;

    iterator(ibuffer& buffer)
        : buffer(&buffer), ptr(&buffer.elements.front()), x(0), y(0), idx(0) {}

    iterator(ibuffer& buffer, pos_t x, pos_t y)
        : buffer(&buffer), ptr(&buffer.elements[idx]), x(x), y(y),
          idx(buffer.pos_to_idx(x, y)) {}

    reference operator*() const { return *ptr; }
    pointer operator->() const { return ptr; }

    iterator& operator++() { // prefix
      ptr++;

      // position logic
      idx++;
      x++;
      if (x >= buffer->width) {
        x = 0;
        y++;
      }

      return *this;
    }
    // makes a copy of the current iterator/location, then increments and
    // returns the original position
    iterator operator++(int) { // postfix
      iterator tmp(*this);
      ++(*this);
      return tmp;
    }

    friend bool operator==(iterator const& a, iterator const& b) {
      return a.ptr == b.ptr;
    }
    friend bool operator!=(iterator const& a, iterator const& b) {
      return a.ptr != b.ptr;
    }

    inline pos_t get_x() { return x; }
    inline pos_t get_y() { return y; }
    inline pos_t get_idx() { return idx; }

  private:
    // bad idea, just doing this to make end more efficient
    iterator(ibuffer& buffer, pointer ptr) : buffer(&buffer), ptr(ptr) {}

    ibuffer* buffer;
    pointer ptr;

    size_t idx;
    pos_t x, y;

    friend ibuffer;
  };

private:
  const size_t width;
  const size_t height;
  const float2 dim;

  size_t length;
  std::vector<pixel> elements;
  pixel def;

public:
  ibuffer(size_t width, size_t height, pixel def = pixel())
      : width(width), height(height), dim((float)width, (float)height),
        def(def), length(width * height), elements(length) {}

  template <typename Iterator>
  ibuffer(size_t width, size_t height, pixel def, Iterator begin, Iterator end,
          bool flip_x = false, bool flip_y = false)
      : ibuffer(width, height, def) {
    set_from(begin, end, flip_x, flip_y);
  }

  void set(pos_t x, pos_t y, pixel val) { elements[pos_to_idx(x, y)] = val; }

  void set(pos_t idx, pixel val) { elements[idx] = val; }

  void set_el(pos_t x, pos_t y, pos_t z, T val) {
    elements[pos_to_idx(x, y)][z] = val;
  }

  pixel& get(pos_t x, pos_t y) { return elements[pos_to_idx(x, y)]; }

  pixel const& cget(pos_t x, pos_t y) const {
    return elements[pos_to_idx(x, y)];
  }

  pixel& get(size_t idx) { return elements[idx]; }

  pixel get_or_def(pos_t x, pos_t y) const {
    if (x < 0 || x >= width || y < 0 || y >= height) {
      return def;
    }
    return elements[pos_to_idx(x, y)];
  }

  pixel get_or_loop(pos_t x, pos_t y) const {
    x = x % width;
    y = y % height;
    return elements[pos_to_idx(x, y)];
  }

  pixel get_or_clamp(pos_t x, pos_t y) const {
    x = std::clamp(x, (pos_t)0, (pos_t)width - 1);
    y = std::clamp(y, (pos_t)0, (pos_t)height - 1);
    return elements[pos_to_idx(x, y)];
  }

  // todo
  pixel get_or_mirror(pos_t x, pos_t y) const {
    x = std::abs(x);
    y = std::abs(y);

    return elements[pos_to_idx(x, y)];
  }

  // todo: come up with a unified way of handling different wrapping methods
  pixel get_bilinear_loop(float x, float y) const {
    float cx = std::floor(x);
    float cy = std::floor(y);

    float tx = x - cx;
    float ty = y - cy;

    pixel Ptl = get_or_loop(cx, cy);
    pixel Ptr = get_or_loop(cx + 1, cy);
    pixel Pbl = get_or_loop(cx, cy + 1);
    pixel Pbr = get_or_loop(cx + 1, cy + 1);

    return pixel::lerp(ty, pixel::lerp(tx, Ptl, Ptr),
                       pixel::lerp(tx, Pbl, Pbr));
  }

  pixel get_bilinear_clamp(float x, float y) const {
    float cx = std::floor(x);
    float cy = std::floor(y);

    float tx = x - cx;
    float ty = y - cy;

    pixel Ptl = get_or_clamp(cx, cy);
    pixel Ptr = get_or_clamp(cx + 1, cy);
    pixel Pbl = get_or_clamp(cx, cy + 1);
    pixel Pbr = get_or_clamp(cx + 1, cy + 1);

    return pixel::lerp(ty, pixel::lerp(tx, Ptl, Ptr),
                       pixel::lerp(tx, Pbl, Pbr));
  }

  pixel get_bilinear_def(float x, float y) const {
    float cx = std::floor(x);
    float cy = std::floor(y);

    float tx = x - cx;
    float ty = y - cy;

    pixel Ptl = get_or_def(cx, cy);
    pixel Ptr = get_or_def(cx + 1, cy);
    pixel Pbl = get_or_def(cx, cy + 1);
    pixel Pbr = get_or_def(cx + 1, cy + 1);

    return pixel::lerp(ty, pixel::lerp(tx, Ptl, Ptr),
                       pixel::lerp(tx, Pbl, Pbr));
  }

  T get_el(pos_t x, pos_t y, pos_t z) const {
    return elements[pos_to_idx(x, y)][z];
  }

  inline size_t pos_to_idx(pos_t x, pos_t y) const { return y * width + x; }

  float2 from_norm_coords(float2 coords) const { return coords * dim; }

  float2 from_norm_cords(float x, float y) const {
    return float2(dim[0] * x, dim[1] * y);
  }

  inline size_t get_width() const { return width; }

  inline size_t get_height() const { return height; }

  inline size_t get_length() const { return length; }

  inline size_t get_extended_length() const { return length * depth; }

  std::vector<pixel>& data() { return elements; }

  void fill(T val) {
    for (auto& e : elements)
      e = val;
  }

  void fill(pixel val) {
    for (auto& e : elements)
      e = val;
  }

  iterator begin() { return iterator(*this); }
  iterator end() { return iterator(*this, &elements.back() + 1); }

  void set_from(std::vector<T> const& arr) {
    if (arr.size() != get_extended_length()) {
      throw std::invalid_argument{"trying to set ibuffer with an array of size "
                                  "differing from the buffers extended "
                                  "length"};
    }

    for (size_t y = 0; y < height; y++) {
      size_t scanned = y * width;
      for (size_t x = 0; x < width; x++) {
        size_t idx = scanned + x;  // index into the pixel vector
        size_t eidx = idx * depth; // extended index

        pixel& p = get(idx);
        unroll<depth>([&, this](auto i) {
          // copy arr[eidx..eidx+depth+1] into pixel
          p[i] = arr[eidx + i];
        });
      }
    }
  }

  template <typename Iterator>
  void set_from(Iterator begin, Iterator end, bool flip_x = false,
                bool flip_y = false) {
    Iterator it = begin;

    for (size_t y = 0; y < height; y++) {
      size_t scanned = (flip_y ? height - y - 1 : y) * width;
      for (size_t x = 0; x < width; x++) {
        size_t idx = scanned + (flip_x ? width - x - 1
                                       : x); // index into the pixel vector
        size_t eidx = idx * depth;           // extended index

        pixel& p = get(idx);
        unroll<depth>([&, this](auto i) {
          if (it == end) {
            throw std::invalid_argument{"trying to initialize ibuffer from an "
                                        "iterable with incomplete length"};
          }
          // copy arr[eidx..eidx+depth+1] into pixel
          p[i] = *it;
          it++;
        });
      }
    }
  }

  // pretty much just swaps the assignment operands from set_from(vector<T>)
  std::vector<T> to_arr() {
    std::vector<T> arr(get_extended_length());

    for (size_t y = 0; y < height; y++) {
      size_t scanned = y * width;
      for (size_t x = 0; x < width; x++) {
        size_t idx = scanned + x;  // index into the pixel vector
        size_t eidx = idx * depth; // extended index

        pixel& p = get(idx);
        unroll<depth>([&, this](auto i) {
          // copy pixel into arr[eidx..eidx+depth+1]
          arr[eidx + i] = p[i];
        });
      }
    }

    return arr;
  }

  void draw(ibuffer const& other, size_t xstart, size_t ystart) {
    size_t xend = std::min(xstart + other.width, width);
    size_t yend = std::min(ystart + other.height, height);

    for (size_t y = ystart; y < yend; y++) {
      for (size_t x = xstart; x < xend; x++) {
        auto const& p = other.cget(x - xstart, y - ystart);
        set(x, y, p);
      }
    }
  }

  void draw(ibuffer const& other, size_t xstart, size_t ystart,
            // applies a mask to the draw operation, most likely an alpha mask
            std::function<bool(pixel const&)> const& mask) {
    size_t xend = std::min(xstart + other.width, width);
    size_t yend = std::min(ystart + other.height, height);

    for (size_t y = ystart; y < yend; y++) {
      for (size_t x = xstart; x < xend; x++) {
        auto const& p = other.cget(x - xstart, y - ystart);
        if (mask(p)) {
          set(x, y, p);
        }
      }
    }
  }

  void apply(std::function<pixel(pixel const&)> const& filter) {
    auto done = end();
    for (auto it = begin(); it != done; it++) {
      *it = filter(*it);
    }
  }

  void scale(T s) {
    apply([s](auto p) { return p * s; });
  }

  static ibuffer scale(ibuffer const& original, T s) {
    ibuffer buffer(original);
    buffer.scale(s);
    return buffer;
  }

  template <typename TT> ibuffer<TT, depth> cast() {
    vec<TT, depth> new_def = def;

    ibuffer<TT, depth> casted(width, height, new_def);
    auto& casted_elements = casted.data();

    for (size_t i = 0; i < length; i++) {
      casted_elements[i] = elements[i];
    }
    return casted;
  }

  // similar to apply, but generates a new buffer possibly of a different type
  // and depth
  template <typename TT = T, size_t M = depth>
  ibuffer<TT, M>
  map(std::function<typename ibuffer<TT, M>::pixel(pixel const&)> const&
          filter) {
    ibuffer<TT, M> casted(width, height);
    auto& casted_elements = casted.data();

    for (size_t i = 0; i < length; i++) {
      casted_elements[i] = filter(elements[i]);
    }
    return casted;
  }
};

typedef ibuffer<char, 1> cbuffer1;
typedef ibuffer<char, 2> cbuffer2;
typedef ibuffer<char, 3> cbuffer3;
typedef ibuffer<char, 4> cbuffer4;

typedef ibuffer<int, 1> ibuffer1;
typedef ibuffer<int, 2> ibuffer2;
typedef ibuffer<int, 3> ibuffer3;
typedef ibuffer<int, 4> ibuffer4;

typedef ibuffer<float, 1> fbuffer1;
typedef ibuffer<float, 2> fbuffer2;
typedef ibuffer<float, 3> fbuffer3;
typedef ibuffer<float, 4> fbuffer4;
