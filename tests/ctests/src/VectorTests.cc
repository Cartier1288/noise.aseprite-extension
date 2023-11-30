#include "vec.h"

#include <assert.h>
#include <iostream>

int main(int argc, char** argv) {
    float4 all1(1.0f);
    std::cout << all1 << std::endl;
    assert(all1.sum() == 4.0f);

    float4 v1(2.0f, 3.0f, 4.0f, 1.0f);
    float4 v2(12.0f);

    std::cout << v2-v1 << std::endl;
    std::cout << v2+v1 << std::endl;
    std::cout << v2*v1 << std::endl;
    std::cout << v2/v1 << std::endl;

    float4 result = v2 - v1;
    result = v2 + v1;
    result = v2 * v1;
    result = v2 / v1;

    result += 123;
    std::cout << result << std::endl;

    result += v2;
    std::cout << result << std::endl;

    result += result;
    std::cout << result << std::endl;

    std::cout << result.dot(float4(1.0f)) << std::endl;
    std::cout << result.dot(v2) << std::endl;

    auto result2 = result.get<0,1>();
    std::cout << result2 << std::endl;

    auto result8 = result.get<0,1,2,3,3,2,1,0>();
    std::cout << result8 << std::endl;

    auto result3 = vec(1.0f, 2.0f, 3.0f);
    std::cout << result3 << std::endl;

    result3.set<0,2>(3.0, 5.0);
    std::cout << result3 << std::endl;

    auto result4 = result3.extend(4.0f);
    std::cout << result4 << std::endl;

    float2 dots(5.0f, 11.0f);
    float2 half2(0.5f, 0.5f);

    std::cout << float2::dot(dots, half2) << std::endl;
    assert(float2::dot(dots, half2) == 8.0f);

    float2 rounded = (dots/2).round();
    std::cout << rounded << std::endl;
    assert(rounded[0] == 3.0f && rounded[1] == 6.0f);

    rounded = float2(1.25f, 1.75f).round();
    std::cout << rounded << std::endl;
    assert(rounded[0] == 1.0f && rounded[1] == 2.0f);
    
    float4 absd = float4(-0.25f, -0.5f, -0.75f, -1.0f);
    absd.setv<0,2>(float2::abs(absd.get<0,2>()));
    std::cout << absd << std::endl;
    assert(absd[0] == 0.25f && absd[1] == -0.5f && absd[2] == 0.75f && absd[3] == -1.0f);

    float3 stepped = float3::step(0.5f, float3(0.5, 0.25, 0.75));
    std::cout << stepped << std::endl;
    assert(stepped[0] == 1.0f && stepped[1] == 0.0f && stepped[2] == 1.0f);

    bool3 stepped_b = bool3(stepped);
    std::cout << stepped_b << std::endl;
    assert(stepped_b[0] && !stepped_b[1] && stepped_b[2]);

    float3 orig(123.0f, 123.0f, 123.0f);
    float3 vals(1.0f, 2.0f, 3.0f);
    float3 movcd = vals.movc(stepped_b, orig);
    std::cout << movcd << std::endl;
    assert(movcd[0] == 123.0f && movcd[1] == 2.0f && movcd[2] == 123.0f);

    return 0;
}