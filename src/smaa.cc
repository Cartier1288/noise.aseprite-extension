#include "smaa.h"
#include "larray.h"
#include "utils.h"

#include "SMAA/areatex.h"
#include "SMAA/searchtex.h"

/**
 * Note: seeing as this is pretty much just a port of the HLSL version of SMAA
 * to C++, the following notice from the original software is included:
 *
 * Copyright (C) 2013 Jorge Jimenez (jorge@iryoku.com)
 * Copyright (C) 2013 Jose I. Echevarria (joseignacioechevarria@gmail.com)
 * Copyright (C) 2013 Belen Masia (bmasia@unizar.es)
 * Copyright (C) 2013 Fernando Navarro (fernandn@microsoft.com)
 * Copyright (C) 2013 Diego Gutierrez (diegog@unizar.es)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is furnished to
 * do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software. As clarification, there
 * is no requirement that the copyright notice and permission be included in
 * binary distributions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

/* Note:
 * The original SMAA had a lot of hardware/GPU optimized code. In particular,
 * the original made use of hardware bilinear filtering often, e.g., to optimize
 * the search algorithm. This port still uses that bilinear filtering technique
 * although it is doubtful that it has any kind of performance increase on the
 * CPU using a simple buffer from memory for textures.
 *
 * Future changes might see this approach turn back into the more simplified
 * unoptimized version, but for now it is simpler to just use the "optimized"
 * technique as is.
 */

#define SMAA_PRESET_HIGH 1

#if defined(SMAA_PRESET_LOW)
#define SMAA_THRESHOLD 0.15
#define SMAA_MAX_SEARCH_STEPS 4
#define SMAA_DISABLE_DIAG_DETECTION
#define SMAA_DISABLE_CORNER_DETECTION
#elif defined(SMAA_PRESET_MEDIUM)
#define SMAA_THRESHOLD 0.1
#define SMAA_MAX_SEARCH_STEPS 8
#define SMAA_DISABLE_DIAG_DETECTION
#define SMAA_DISABLE_CORNER_DETECTION
#elif defined(SMAA_PRESET_HIGH)
#define SMAA_THRESHOLD 0.1
#define SMAA_MAX_SEARCH_STEPS 16
#define SMAA_MAX_SEARCH_STEPS_DIAG 8
#define SMAA_CORNER_ROUNDING 25
#elif defined(SMAA_PRESET_ULTRA)
#define SMAA_THRESHOLD 0.05
#define SMAA_MAX_SEARCH_STEPS 32
#define SMAA_MAX_SEARCH_STEPS_DIAG 16
#define SMAA_CORNER_ROUNDING 25
#endif

#ifndef SMAA_MAX_COLOR
#define SMAA_MAX_COLOR 255.0
#endif

/**
 * SMAA_THRESHOLD specifies the threshold or sensitivity to edges.
 * Lowering this value you will be able to detect more edges at the expense of
 * performance.
 *
 * Range: [0, 0.5]
 *   0.1 is a reasonable value, and allows to catch most visible edges.
 *   0.05 is a rather overkill value, that allows to catch 'em all.
 *
 *   If temporal supersampling is used, 0.2 could be a reasonable value, as low
 *   contrast edges are properly filtered by just 2x.
 */
#ifndef SMAA_THRESHOLD
#define SMAA_THRESHOLD 0.1
#endif

/**
 * SMAA_DEPTH_THRESHOLD specifies the threshold for depth edge detection.
 *
 * Range: depends on the depth range of the scene.
 */
#ifndef SMAA_DEPTH_THRESHOLD
#define SMAA_DEPTH_THRESHOLD
#endif

#define SMAA_SCALED_THRESHOLD (SMAA_THRESHOLD * SMAA_MAX_COLOR)

/**
 * SMAA_MAX_SEARCH_STEPS specifies the maximum steps performed in the
 * horizontal/vertical pattern searches, at each side of the pixel.
 *
 * In number of pixels, it's actually the double. So the maximum line length
 * perfectly handled by, for example 16, is 64 (by perfectly, we meant that
 * longer lines won't look as good, but still antialiased).
 *
 * Range: [0, 112]
 */
#ifndef SMAA_MAX_SEARCH_STEPS
#define SMAA_MAX_SEARCH_STEPS 16
#endif

/**
 * SMAA_MAX_SEARCH_STEPS_DIAG specifies the maximum steps performed in the
 * diagonal pattern searches, at each side of the pixel. In this case we jump
 * one pixel at time, instead of two.
 *
 * Range: [0, 20]
 *
 * On high-end machines it is cheap (between a 0.8x and 0.9x slower for 16
 * steps), but it can have a significant impact on older machines.
 *
 * Define SMAA_DISABLE_DIAG_DETECTION to disable diagonal processing.
 */
#ifndef SMAA_MAX_SEARCH_STEPS_DIAG
#define SMAA_MAX_SEARCH_STEPS_DIAG 8
#endif

/**
 * SMAA_CORNER_ROUNDING specifies how much sharp corners will be rounded.
 *
 * Range: [0, 100]
 *
 * Define SMAA_DISABLE_CORNER_DETECTION to disable corner processing.
 */
#ifndef SMAA_CORNER_ROUNDING
#define SMAA_CORNER_ROUNDING 25
#endif

/**
 * If there is an neighbor edge that has SMAA_LOCAL_CONTRAST_FACTOR times
 * bigger contrast than current edge, current edge will be discarded.
 *
 * This allows to eliminate spurious crossing edges, and is based on the fact
 * that, if there is too much contrast in a direction, that will hide
 * perceptually contrast in the other neighbors.
 */
#ifndef SMAA_LOCAL_CONTRAST_ADAPTATION_FACTOR
#define SMAA_LOCAL_CONTRAST_ADAPTATION_FACTOR 2.0
#endif

/**
 * Predicated thresholding allows to better preserve texture details and to
 * improve performance, by decreasing the number of detected edges using an
 * additional buffer like the light accumulation buffer, object ids or even the
 * depth buffer (the depth buffer usage may be limited to indoor or short range
 * scenes).
 *
 * It locally decreases the luma or color threshold if an edge is found in an
 * additional buffer (so the global threshold can be higher).
 *
 * This method was developed by Playstation EDGE MLAA team, and used in
 * Killzone 3, by using the light accumulation buffer. More information here:
 *     http://iryoku.com/aacourse/downloads/06-MLAA-on-PS3.pptx
 */
#ifndef SMAA_PREDICATION
#define SMAA_PREDICATION 0
#endif

/**
 * Threshold to be used in the additional predication buffer.
 *
 * Range: depends on the input, so you'll have to find the magic number that
 * works for you.
 */
#ifndef SMAA_PREDICATION_THRESHOLD
#define SMAA_PREDICATION_THRESHOLD 0.01
#endif

/**
 * How much to scale the global threshold used for luma or color edge
 * detection when using predication.
 *
 * Range: [1, 5]
 */
#ifndef SMAA_PREDICATION_SCALE
#define SMAA_PREDICATION_SCALE 2.0
#endif

/**
 * How much to locally decrease the threshold.
 *
 * Range: [0, 1]
 */
#ifndef SMAA_PREDICATION_STRENGTH
#define SMAA_PREDICATION_STRENGTH 0.4
#endif

/**
 * Temporal reprojection allows to remove ghosting artifacts when using
 * temporal supersampling. We use the CryEngine 3 method which also introduces
 * velocity weighting. This feature is of extreme importance for totally
 * removing ghosting. More information here:
 *    http://iryoku.com/aacourse/downloads/13-Anti-Aliasing-Methods-in-CryENGINE-3.pdf
 *
 * Note that you'll need to setup a velocity buffer for enabling reprojection.
 * For static geometry, saving the previous depth buffer is a viable
 * alternative.
 */
#ifndef SMAA_REPROJECTION
#define SMAA_REPROJECTION 0
#endif

/**
 * SMAA_REPROJECTION_WEIGHT_SCALE controls the velocity weighting. It allows to
 * remove ghosting trails behind the moving object, which are not removed by
 * just using reprojection. Using low values will exhibit ghosting, while using
 * high values will disable temporal supersampling under motion.
 *
 * Behind the scenes, velocity weighting removes temporal supersampling when
 * the velocity of the subsamples differs (meaning they are different objects).
 *
 * Range: [0, 80]
 */
#ifndef SMAA_REPROJECTION_WEIGHT_SCALE
#define SMAA_REPROJECTION_WEIGHT_SCALE 30.0
#endif

//-----------------------------------------------------------------------------
// Texture Access Defines

#ifndef SMAA_SEARCHTEX_SELECT
#define SMAA_SEARCHTEX_SELECT(sample) sample[0]
#endif

#ifndef SMAA_DECODE_VELOCITY
#define SMAA_DECODE_VELOCITY(sample) sample.get<0, 2>()
#endif

//-----------------------------------------------------------------------------
// Non-Configurable Defines

#define SMAA_AREATEX_MAX_DISTANCE 16
#define SMAA_AREATEX_MAX_DISTANCE_DIAG 20
#define SMAA_AREATEX_PIXEL_SIZE (1.0 / float2(160.0, 560.0))
#define SMAA_AREATEX_SUBTEX_SIZE (1.0 / 7.0)
#define SMAA_SEARCHTEX_SIZE float2(66.0, 33.0)
#define SMAA_SEARCHTEX_PACKED_SIZE float2(64.0, 16.0)
#define SMAA_CORNER_ROUNDING_NORM (float(SMAA_CORNER_ROUNDING) / 100.0)

/* == PHASE 1 - Edge Detection ============================================= */

static float2 SMAAColorEdgeDetectionPS(size_t x, size_t y, float4 offset[3], fbuffer4 const& tex) {
#define vmax(v) std::max(std::max(v[0], v[1]), v[2])
  const float2 discard = float2{0.0f, 0.0f};

  // TODO: add custom threshold as parameter to SMAA class
  float2 threshold = float2(SMAA_SCALED_THRESHOLD, SMAA_SCALED_THRESHOLD);

  float4 delta;

  float3 C = tex.cget(x, y).get<0, 1, 2>();

  float3 Cleft = tex.get_or_clamp(offset[0][0], offset[0][1]).get<0, 1, 2>();
  float3 t = float3::abs(C - Cleft);
  delta[0] = vmax(t);

  float3 Ctop = tex.get_or_clamp(offset[0][2], offset[0][3]).get<0, 1, 2>();
  t = float3::abs(C - Ctop);
  delta[1] = vmax(t);

  // typical threshold
  float2 edges = float2::step(threshold, delta.get<0, 1>());

  // no edges, return blank -- for this it is equivalent to discarding the
  // fragment
  if (edges[0] + edges[1] == 0.0f)
    return discard;

  float3 Cright = tex.get_or_clamp(offset[1][0], offset[1][1]).get<0, 1, 2>();
  t = float3::abs(C - Cright);
  delta[2] = vmax(t);

  float3 Cbottom = tex.get_or_clamp(offset[1][2], offset[1][3]).get<0, 1, 2>();
  t = float3::abs(C - Cbottom);
  delta[3] = vmax(t);

  // direct neighorhood max delta, overwrite delta.zw later
  float2 max_delta = float2::max(delta.get<0, 1>(), delta.get<2, 3>());

  float3 Cleftleft = tex.get_or_clamp(offset[2][0], offset[2][1]).get<0, 1, 2>();
  t = float3::abs(C - Cleftleft);
  delta[2] = vmax(t);

  float3 Ctoptop = tex.get_or_clamp(offset[2][2], offset[2][3]).get<0, 1, 2>();
  t = float3::abs(C - Ctoptop);
  delta[3] = vmax(t);

  max_delta = float2::max(max_delta, delta.get<2, 3>());
  float final_delta = std::max(max_delta[0], max_delta[1]);

  // adaptive double threshold for local contrast
  edges *= float2::step(final_delta, delta.get<0, 1>() * SMAA_LOCAL_CONTRAST_ADAPTATION_FACTOR);

  return edges;
#undef vmax
}

/* ========================================================================= */

/* == PHASE 2 - Blending Weight Calculations =============================== */

#define SMAA_DISABLE_CORNER_DETECTION 1

static const float2 zero2(0.0f, 0.0f);
static const float2 one2(1.0f, 1.0f);
static const float2 two2(2.0f, 2.0f);

static float2 SMAADecodeDiagBilinearAccess(float2 e) {
  e[0] = e[0] * std::abs(5.0f * e[0] - 5.0f * 0.75f);
  return e.round();
}

static float4 SMAADecodeDiagBilinearAccess(float4 e) {
  float2 rb = e.get<0, 2>();
  e.setv<0, 2>(rb * float2::abs(5.0f * rb - 5.0f * 0.75f));
  return e.round();
}

void SMAADetectHorizontalCornerPattern(float2& weights, float4 texcoord, float2 d,
                                       fbuffer2 const& edges) {
#ifndef SMAA_DISABLE_CORNER_DETECTION
  float2 left_right = float2::step(d, d.get<1, 0>());
  float2 rounding = (1.0f - SMAA_CORNER_ROUNDING_NORM) * left_right;

  rounding /= left_right[0] + left_right[1];

  float2 factor = one2;
  factor[0] -= rounding[0] * edges.get_bilinear_def(texcoord[0] + 0.0f, texcoord[1] + 1.0f)[0];
  factor[0] -= rounding[1] * edges.get_bilinear_def(texcoord[2] + 1.0f, texcoord[3] + 1.0f)[0];
  factor[1] -= rounding[0] * edges.get_bilinear_def(texcoord[0] + 0.0f, texcoord[1] + -2.0f)[0];
  factor[1] -= rounding[1] * edges.get_bilinear_def(texcoord[2] + 1.0f, texcoord[3] + -2.0f)[0];

  weights *= factor.clamp(0.0f, 1.0f);
#endif
}

void SMAADetectVerticalCornerPattern(float2& weights, float4 texcoord, float2 d,
                                     fbuffer2 const& edges) {
#ifndef SMAA_DISABLE_CORNER_DETECTION
  float2 left_right = float2::step(d, d.get<1, 0>());
  float2 rounding = (1.0f - SMAA_CORNER_ROUNDING_NORM) * left_right;

  rounding /= left_right[0] + left_right[1];

  float2 factor = one2;
  factor[0] -= rounding[0] * edges.get_bilinear_def(texcoord[0] + 1.0f, texcoord[1] + 0.0f)[0];
  factor[0] -= rounding[1] * edges.get_bilinear_def(texcoord[2] + 1.0f, texcoord[3] + 1.0f)[0];
  factor[1] -= rounding[0] * edges.get_bilinear_def(texcoord[0] + -2.0f, texcoord[1] + 0.0f)[0];
  factor[1] -= rounding[1] * edges.get_bilinear_def(texcoord[2] + -2.0f, texcoord[3] + 0.0f)[0];

  weights *= factor.clamp(0.0f, 1.0f);
#endif
}

static const float2 half2(0.5f, 0.5f);
static float2 SMAASearchDiag1(float x, float y, float2 dir, float2& e, fbuffer2 const& edges) {
  float4 coord = float4(x, y, -1.0, 1.0);
  float3 t = float3(1.0f);        // how much we want to move in each axis
  float3 dir3 = dir.extend(1.0f); // axis extended to 3 elements
  // keep pushing search by t * dir3 until we hit the max number of search steps
  // or e \cdot <0.5, 0.5> exceeds 0.9
  while (coord[2] < float(SMAA_MAX_SEARCH_STEPS_DIAG - 1) && coord[3] > 0.9f) {
    coord.setv<0, 1, 2>(t * dir3 + coord.get<0, 1, 2>());
    e = edges.get_bilinear_def(coord[0], coord[1]);
    coord[3] = float2::dot(e, half2);
  }
  return coord.get<2, 3>();
}

static float2 SMAASearchDiag2(float x, float y, float2 dir, float2& e, fbuffer2 const& edges) {
  float4 coord = float4(x, y, -1.0, 1.0);
  coord[0] += 0.25f;
  float3 t = float3(1.0f);        // how much we want to move in each axis
  float3 dir3 = dir.extend(1.0f); // axis extended to 3 elements
  // keep pushing search by t * dir3 until we hit the max number of search steps
  // or e \cdot <0.5, 0.5> exceeds 0.9
  while (coord[2] < float(SMAA_MAX_SEARCH_STEPS_DIAG - 1) && coord[3] > 0.9f) {
    coord.setv<0, 1, 2>(t * dir3 + coord.get<0, 1, 2>());

    e = edges.get_bilinear_def(coord[0], coord[1]);
    e = SMAADecodeDiagBilinearAccess(e);

    coord[3] = float2::dot(e, half2);
  }
  return coord.get<2, 3>();
}

static const float2 MAXAREADIAG2 =
    float2(SMAA_AREATEX_MAX_DISTANCE_DIAG, SMAA_AREATEX_MAX_DISTANCE_DIAG);
static float2 SMAAAreaDiag(float2 dist, float2 e, float offset, fbuffer2 const& area) {
  float2 texcoord = MAXAREADIAG2 * e + dist;
  // texcoord += 0.5f; // bias

  // diagonal areas are on the second half of the texture
  texcoord[0] += AREATEX_WIDTH / 2.0f;
  texcoord[1] += AREATEX_HEIGHT * SMAA_AREATEX_SUBTEX_SIZE * offset;

  return area.get_bilinear_def(texcoord[0], texcoord[1]);
}

static const float2 MAXAREA2 = float2(SMAA_AREATEX_MAX_DISTANCE, SMAA_AREATEX_MAX_DISTANCE);
float2 SMAAArea(float2 dist, float e1, float e2, float offset, fbuffer2 const& area) {
  // round to avoid precision errors from bilinear filtering
  float2 texcoord = MAXAREA2 * (4.0f * float2(e1, e2)).round() + dist;

  // bias
  // texcoord += 0.5f;

  // move to proper place, according to subpixel offset
  texcoord[1] += AREATEX_HEIGHT * SMAA_AREATEX_SUBTEX_SIZE * offset;

  return area.get_bilinear_def(texcoord[0], texcoord[1]);
}

static const float2 d_left_down(-1.0f, 1.0f);
static const float2 d_left_up(-1.0f, -1.0f);
static const float2 d_right_down(1.0f, 1.0f);
static const float2 d_right_up(1.0f, -1.0f);
static float2 SMAACalculateDiagWeights(float x, float y, float2 e, float4 subsample_indices,
                                       fbuffer2 const& edges, fbuffer2 const& area) {
  float2 weights(0.0f);

  float4 d;
  float2 end;

  // search for line ends
  if (e[0] > 0.0f) {
    d.setv<0, 2>(SMAASearchDiag1(x, y, d_left_down, end, edges));
    d[0] += float(end[1] > 0.9);
  } else
    d.set<0, 2>(0.0f, 0.0f);

  d.setv<1, 3>(SMAASearchDiag1(x, y, d_right_up, end, edges));

  float4 base_coords = float4{x, y, x, y};
  if (d[0] + d[1] > 2.0f) {
    // fetch crossing edges
    float4 coords = float4(-d[0] + 0.25f, d[0], d[1], -d[1] - 0.25) + base_coords;
    float4 c;

    c.setv<0, 1>(edges.get_bilinear_def(coords[0] - 1, coords[1] + 0));
    c.setv<2, 3>(edges.get_bilinear_def(coords[2] + 1, coords[3] + 0));
    c.setv<1, 0, 3, 2>(SMAADecodeDiagBilinearAccess(c));

    // merge crossing edges _at each side_
    float2 cc = two2 * c.get<0, 2>() + c.get<1, 3>();
    cc.movc(bool2(float2::step(0.9f, d.get<2, 3>())), zero2);

    weights += SMAAAreaDiag(d.get<0, 1>(), cc, subsample_indices[2], area);
  }

  // search for line ends
  d.setv<0, 2>(SMAASearchDiag2(x, y, d_left_up, end, edges));
  if (edges.get_bilinear_def(x + 1, y)[0] > 0.0f) {
    d.setv<1, 3>(SMAASearchDiag2(x, y, d_right_down, end, edges));
    d[1] += float(end[1] > 0.9);
  } else
    d.set<1, 3>(0.0f, 0.0f);

  if (d[0] + d[1] > 2.0f) {
    // once again fetch crossing edges
    float4 coords = float4(-d[0], -d[0], d[1], d[1]) + base_coords;
    float4 c;
    c[0] = edges.get_bilinear_def(coords[0] - 1, coords[1] - 0)[1];
    c[1] = edges.get_bilinear_def(coords[0] - 0, coords[1] - 1)[0];
    c.setv<2, 3>(edges.get_bilinear_def(coords[2] + 1, coords[3] + 0).get<1, 0>());

    float2 cc = two2 * c.get<0, 2>() + c.get<1, 3>();
    cc.movc(bool2(float2::step(0.9f, d.get<2, 3>())), zero2);

    weights += SMAAAreaDiag(d.get<0, 1>(), cc, subsample_indices[3], area).get<1, 0>();
  }

  return weights;
}

static float SMAASearchLength(float2 e, float offset, fbuffer1 const& search) {
  float2 scale = SMAA_SEARCHTEX_SIZE * float2(0.5, -1.0);
  float2 bias = SMAA_SEARCHTEX_SIZE * float2(offset, 1.0);

  // scale and bias to access texel centers
  scale += float2(-1.0f, 1.0f);
  bias += float2(0.0f, -1.0f);

  scale *= 1.0f / SMAA_SEARCHTEX_PACKED_SIZE;
  bias *= 1.0f / SMAA_SEARCHTEX_PACKED_SIZE;

  float2 coords = scale * e + bias;
  coords = search.from_norm_coords(coords);
  float len = search.get_bilinear_def(coords[0], coords[1])[0];

  return len;
}

static float SMAASearchXLeft(float x, float y, float end, fbuffer2 const& edges,
                             fbuffer1 const& search) {

  float2 e = float2(0.0f, 1.0f);
  while (x > end && e[1] > 0.8281f && // all edges activated ?
         e[0] == 0.0f                 // no crossing edge ?
  ) {
    // since we use an offset + bilinear filtering to grab four pixels, there
    // are 16 possible values for e (since each pixel is either active or not)
    // and since the offset is uneven they are all unique we stop when either
    // all edges are active, we reach a crossing edge (i.e., going the other way
    // than we are searching), or we run out of allowed search steps
    e = edges.get_bilinear_def(x, y);

    // two since we are querying two pixels in each axis each time
    x += -2.0f;
  }

  float offset = -(255.0f / 127.0f) * SMAASearchLength(e, 0.0f, search) + 3.25;

  return offset + x;
}

static float SMAASearchXRight(float x, float y, float end, fbuffer2 const& edges,
                              fbuffer1 const& search) {

  float2 e = float2(0.0f, 1.0f);
  while (x < end && e[1] > 0.8281 && // all edges activated ?
         e[0] == 0.0f                // no crossing edge ?
  ) {
    e = edges.get_bilinear_def(x, y);
    x += 2.0f;
  }

  float offset = -(255.0f / 127.0f) * SMAASearchLength(e, 0.5f, search) + 3.25;

  return -offset + x;
}

static float SMAASearchYUp(float x, float y, float end, fbuffer2 const& edges,
                           fbuffer1 const& search) {

  float2 e = float2(1.0f, 0.0f);
  while (y > end && e[0] > 0.8281 && // all edges activated ?
         e[1] == 0.0f                // no crossing edge ?
  ) {
    e = edges.get_bilinear_def(x, y);
    y += -2.0f;
  }

  // search length values are 0, 127/255, 254/255
  float offset = -(255.0f / 127.0f) * SMAASearchLength(e.get<1, 0>(), 0.0f, search) + 3.25;

  return offset + y;
}

static float SMAASearchYDown(float x, float y, float end, fbuffer2 const& edges,
                             fbuffer1 const& search) {

  float2 e = float2(1.0f, 0.0f);
  while (y < end && e[0] > 0.8281 && // all edges activated ?
         e[1] == 0.0f                // no crossing edge ?
  ) {
    e = edges.get_bilinear_def(x, y);
    y += 2.0f;
  }

  float offset = -(255.0f / 127.0f) * SMAASearchLength(e.get<1, 0>(), 0.5f, search) + 3.25;

  return -offset + y;
}

#define SMAA_DISABLE_DIAG_DETECTION
#undef SMAA_DISABLE_DIAG_DETECTION

struct ds_t {
  // const char* type;
  size_t x, y;
  float2 d;
  float2 weights;
};
std::vector<ds_t> ds;

// float4 offset[3]
//   offset[0] = texcoord.xyxy + left-right offset
//   offset[0] = texcoord.xyxy + up-down offset
//   offset[2] = offset[0,1] + max search steps
static float4 SMAABlendingWeightCalculation(size_t x, size_t y, float4 offset[3],
                                            fbuffer2 const& edges, fbuffer2 const& area,
                                            fbuffer1 const& search, float4 subsample_indices) {
  float4 weights = float4(0.0f);

  float2 e = edges.cget(x, y);

  if (e[1] > 0.0f) { // NORTH EDGE

#ifndef SMAA_DISABLE_DIAG_DETECTION
    weights.setv<0, 1>(SMAACalculateDiagWeights(x, y, e, subsample_indices, edges, area));
    // diagonals get priority, skip vert/horiz if we find one
    if (weights[0] + weights[1] == 0.0f) {
#endif
      float2 d;

      float3 coords;

      // find distance to the left
      coords[0] = SMAASearchXLeft(offset[0][0], offset[0][1], offset[2][0], edges, search);
      coords[1] = offset[1][1]; // @CROSSING_OFFSET
      d[0] = coords[0];

      // fetch left-crossing edges.
      float e1 = edges.get_bilinear_def(coords[0], coords[1])[0];

      // find distance to the right
      coords[2] = SMAASearchXRight(offset[0][2], offset[0][3], offset[2][1], edges, search);
      d[1] = coords[2];

      // ds.push_back({ "horizontal1", x, y, d });

      // d[0] line length to the left, d[1] line length to the right
      d = float2::abs((d - x).round());

      float2 sqrt_d = d.sqrt();

      // fetch right-crossing edges
      float e2 = edges.get_bilinear_def(coords[2] + 1, coords[1])[0];

      auto areav = SMAAArea(sqrt_d, e1, e2, subsample_indices[1], area);

      // retrieved pattern, now find area
      weights.setv<0, 1>(areav);

      ds.push_back({x, y, d, weights.get<0, 1>()});

      // fix corners
      // coords[1] = y;
      // float2 weights_rg = weights.get<0,1>();
      // SMAADetectHorizontalCornerPattern(weights_rg, coords.get<0,1,2,1>(), d,
      // edges); weights.setv<0,1>(weights_rg);
#ifndef SMAA_DISABLE_DIAG_DETECTION
    } else
      e[0] = 0.0f; // skip vertical processing too if we get a diagonal match
#endif
  }

  if (e[0] > 0.0f) { // WEST EDGE
    float2 d;

    // find distance to the top
    float3 coords;
    coords[1] = SMAASearchYUp(offset[1][0], offset[1][1], offset[2][2], edges, search);
    coords[0] = offset[0][0];
    d[0] = coords[1];

    // fetch top-crossing edges
    float e1 = edges.get_bilinear_def(coords[0], coords[1])[1];

    // find the distance to the bottom
    coords[2] = SMAASearchYDown(offset[1][2], offset[1][3], offset[2][3], edges, search);
    d[1] = coords[2];

    // ds.push_back({ "vertical1", x, y, d });

    // d[0] upward line length, d[1] downward line length
    d = float2::abs((d - y).round());

    float2 sqrt_d = d.sqrt();

    // fetch bottom-crossing edges
    float e2 = edges.get_bilinear_def(coords[0], coords[2] + 1)[1];

    // find area
    weights.setv<2, 3>(SMAAArea(sqrt_d, e1, e2, subsample_indices[0], area));

    ds.push_back({x, y, d, weights.get<2, 3>()});
    // fix corners
    // coords[0] = x;
    // float2 weights_ba = weights.get<2,3>();
    // SMAADetectVerticalCornerPattern(weights_ba, coords.get<0,1,0,2>(), d,
    // edges); weights.setv<2,3>(weights_ba);
  }

  return weights;
}

static float4 SMAANeighborhoodBlending(float x, float y, float4 offset, fbuffer4& colors,
                                       fbuffer4& blending) {
  // fetch blending weights for x,y
  float4 a;
  a[0] = blending.get_or_def(offset[0], offset[1])[3]; // right
  a[1] = blending.get_or_def(offset[2], offset[3])[1]; // top
  a.setv<3, 2>(blending.get_or_def(x, y).get<0, 2>()); // bottom / left

  // is the sum of the blending weights less than some epsilon? (no blending to
  // do here)
  if (a.sum() < 1e-5) {
    float4 color = colors.get(x, y);
    return color;
  } else {
    // max(horizontal) > max(vertical)
    bool h = std::max(a[0], a[2]) > std::max(a[1], a[3]);

    // calculate blending offsets
    float4 blending_offset = float4(0.0f, a[1], 0.0f, a[3]);
    float2 blending_weight = a.get<1, 3>();

    blending_offset.movc(bool4(h), float4(a[0], 0.0f, a[2], 0.0f));
    blending_weight.movc(bool2(h), a.get<0, 2>());
    blending_weight.normalize();

    float4 blending_coord = blending_offset * float4(1.0, 1.0, -1.0, -1.0) + float4(x, y, x, y);

    float4 color =
        blending_weight[0] * colors.get_bilinear_def(blending_coord[0], blending_coord[1]);
    color += blending_weight[1] * colors.get_bilinear_def(blending_coord[2], blending_coord[3]);

    return color;
  }

  return a;
}

SMAA::SMAA() {}

static const float4 base_edge_offsets[3] = {float4{-1.0f, 0.0f, 0.0f, -1.0f},
                                            float4{1.0f, 0.0f, 0.0f, 1.0f},
                                            float4{-2.0f, 0.0f, 0.0f, -2.0f}};

static const float4 base_bw_offsets[3] = {float4{-0.25f, -0.125f, 1.25f, -0.125f},
                                          float4{-0.125f, -0.25f, -0.125f, 1.25f},
                                          float4{-2.0f, 2.0f, -2.0f, 2.0f}};

/* ========================================================================= */

// todo: consider splitting each step into its own function with its own output
// buffer... and maybe templating apply to specify which step to go to. makes it
// easier to see intermediate steps.
ibuffer4 SMAA::apply(fbuffer4 colors) {
  fbuffer4 aabuffer(colors);
  fbuffer2 edges(colors.get_width(), colors.get_height(), float2(0.0f));
  fbuffer4 blending(colors.get_width(), colors.get_height(), float4(0.0f));

  // 1. edge detection
  auto end = colors.end();
  for (auto it = colors.begin(); it != end; it++) {
    float4 coords = float4{it.get_x(), it.get_y(), it.get_x(), it.get_y()};
    float4 offsets[3] = {
        // left, top
        base_edge_offsets[0] + coords,
        // right, bottom
        base_edge_offsets[1] + coords,
        // leftleft, toptop
        base_edge_offsets[2] + coords,
    };
    edges.set(it.get_idx(), SMAAColorEdgeDetectionPS(it.get_x(), it.get_y(), offsets, colors));
  }

  // 2. blending weight
  for (auto it = colors.begin(); it != end; it++) {
    float4 coords = float4{it.get_x(), it.get_y(), it.get_x(), it.get_y()};
    float4 offsets[3] = {
        base_bw_offsets[0] + coords,
        base_bw_offsets[1] + coords,
    };
    offsets[2] = float4(base_bw_offsets[2] * float(SMAA_MAX_SEARCH_STEPS) +
                        float4(offsets[0][0], offsets[0][2], offsets[1][1], offsets[1][3]));
    blending.set(it.get_idx(),
                 SMAABlendingWeightCalculation(it.get_x(), it.get_y(), offsets, edges, area_buffer,
                                               search_buffer, float4(0.0f)));
  }

  // 3. neighborhood blending
  float4 base_offsets(1.0f, 0.0f, 0.0f, 1.0f);
  for (auto it = colors.begin(); it != end; it++) {
    float4 coords = float4{it.get_x(), it.get_y(), it.get_x(), it.get_y()};
    float4 offset = base_offsets + coords;

    aabuffer.set(it.get_idx(),
                 SMAANeighborhoodBlending(it.get_x(), it.get_y(), offset, colors, blending));
  }

  // auto bit = aabuffer.begin();
  //  auto eit = edges.begin();
  //  auto bbit = blending.begin();
  //  for(; bit != aabuffer.end(); bit++, eit++, bbit++) {
  //      auto& edge = *eit;
  //      auto& blend = *bbit;

  //     if(bit.get_x() < AREATEX_WIDTH && bit.get_y() < AREATEX_HEIGHT) {
  //         float2 v = area_buffer.get(bit.get_x(), bit.get_y());
  //         (*bit) = float4(
  //             v[0],
  //             v[1],
  //             0,
  //             255
  //         );
  //     }
  //     if(edge[0] != 0.0f || edge[1] != 0.0f) {
  //         (*bit) = float4(
  //             edge[0] * 100,
  //             edge[1] * 100,
  //             0.0f,
  //             255.0f
  //         );
  //     }
  //     if(bit.get_x() < SEARCHTEX_WIDTH && bit.get_y() < SEARCHTEX_HEIGHT) {
  //         float v = search_buffer.get(bit.get_x(), bit.get_y())[0];
  //         (*bit) = float4(
  //             v,
  //             0,
  //             v,
  //             255
  //         );
  //     }

  //     //if(blend[0] + blend[1] != 0.0f) {
  //         (*bit) = float4(
  //             blend[0],
  //             blend[1],
  //             blend[2] + blend[3],
  //             blend[0] + blend[1] + blend[2] + blend[3] == 0.0f ? 0.0f :
  //             255.0f
  //         );
  //     //}

  // }

  blending.apply([](auto p) {
    return fbuffer4::pixel((p[0] + p[1]) * 120.0f, (p[2] + p[3]) * 120.0f, 0.0f,
                           p.sum() == 0.0f ? 0.0f : 255.0f);
  });

  // aabuffer.draw(blending, 0, 0, [](auto p) {
  //     return p.sum() != 0.0f;
  // });

  // aabuffer.draw(blending, 0, 0);

  // aabuffer.draw(area_buffer.map<float, 4>([](auto p) {
  //     return fbuffer4::pixel(
  //         p[0] * 255.0f,
  //         p[1] * 255.0f,
  //         0.0f,
  //         255.0f
  //     );
  // }), 0, 0);
  // aabuffer.draw(edges.map<float, 4>([](auto p) {
  //     return fbuffer4::pixel(
  //         p[0] * 255.0f,
  //         p[1] * 255.0f,
  //         0.0f,
  //         255.0f
  //     );
  // }), 0, 0);

  // fbuffer4 scaled(orig_buffer.get_width(), orig_buffer.get_height(),
  // float4(0.0f)); bit = aabuffer.begin(); for(; bit != aabuffer.end(); bit++,
  // eit++) {
  //     float x = bit.get_x() / 8.0f;
  //     float y = bit.get_y() / 8.0f;
  //     scaled.set(bit.get_idx(), aabuffer.get_bilinear_def(x,y));
  // }

  return aabuffer.cast<int>();
}

#define GET_NUMBER(idx, field, key)                                                                \
  if (lua_getfield(L, idx, #key) != LUA_TNIL) {                                                    \
    W.field = luaL_checknumber(L, -1);                                                             \
    lua_pop(L, 1);                                                                                 \
  }
#define GET_INTEGER(idx, field, key)                                                               \
  if (lua_getfield(L, idx, #key) != LUA_TNIL) {                                                    \
    W.field = luaL_checkinteger(L, -1);                                                            \
    lua_pop(L, 1);                                                                                 \
  }
#define GET_ENUM(idx, ENUM, enum_last, field, key)                                                 \
  if (lua_getfield(L, idx, #key) != LUA_TNIL) {                                                    \
    int val = luaL_checkinteger(L, -1);                                                            \
    if (val < 0 || val >= enum_last)                                                               \
      luaL_error(L, "invalid enum value passed as field");                                         \
    W.field = (ENUM)val;                                                                           \
    lua_pop(L, 1);                                                                                 \
  }

// parameters: buffer, width, height, opts
int l_SMAA(lua_State* L) {
  size_t width;
  size_t height;

  width = luaL_checknumber(L, 1);
  height = luaL_checknumber(L, 2);

  size_t length = width * height * 4;

  lua_len(L, 3);
  size_t actual_length = lua_tonumber(L, -1);
  lua_pop(L, 1);

  if (length != actual_length)
    lua_error(L);

  auto orig_arr = try_load_array<float>(L, 3, 1, length + 1);

  fbuffer4 buffer(width, height, vec{0, 0, 0, 255});
  buffer.set_from(orig_arr);

  SMAA smaa;
  ibuffer4 aabuffer = smaa.apply(buffer);

  // buffer.fill(vec<int,4>{ 255, 255, 0, 255 });

  // return an ldarray for efficiency
  lua_getglobal(L, "ldarray");

  // add ldarray size argument to stack
  lua_pushinteger(L, length);

  // call ldarray constructor
  if (lua_pcall(L, 1, 1, 0) != LUA_OK)
    return 0;

  auto arr = get_obj<larray<double>>(L, -1);

  // sanity check
  LASSERT(arr->size == length, "unexpected error, array size differs from SMAA buffer");

  arr->from(aabuffer.to_arr());

  return 1;
}

#undef GET_ENUM
#undef GET_INTEGER
#undef GET_NUMBER
