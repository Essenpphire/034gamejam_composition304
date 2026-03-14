// 大色块像素传送门着色器 (Godot 4, canvas_item)
shader_type canvas_item;

// 可调节参数
uniform float radius : hint_range(0.3, 1.0) = 0.8;        // 传送门大小
uniform float block_size : hint_range(2.0, 32.0) = 8.0; // 色块大小 (像素单位)
uniform float twist : hint_range(0.0, 0.5) = 0.2;        // 扭曲强度
uniform float speed : hint_range(0.0, 5.0) = 2.0;        // 动画速度
uniform vec4 color_a : source_color = vec4(0.2, 0.4, 0.8, 1.0); // 主色A
uniform vec4 color_b : source_color = vec4(0.8, 0.3, 0.9, 1.0); // 主色B
uniform vec4 color_c : source_color = vec4(0.1, 0.1, 0.3, 1.0); // 边缘色
uniform bool pixelate = true;                      // 启用像素化

void fragment() {
    // 将UV居中并缩放，使中心为(0,0)
    vec2 uv = UV - 0.5;

    // 计算距离和角度
    float dist = length(uv);
    float angle = atan(uv.y, uv.x);

    // 只在圆形区域内绘制
    float alpha = 1.0 - smoothstep(radius * 0.95, radius, dist);
    if (alpha < 0.01) {
        COLOR = vec4(0.0);
    }

    // 像素化：将uv离散化，产生大色块
    if (pixelate) {
        // 根据距离调整缩放，使边缘的块更大（可选）
        float scale = 1.0;
        uv = floor(uv * 64.0 / block_size) * block_size / 64.0;
    }

    // 动态扭曲：根据角度和时间偏移uv
    float time_angle = angle + TIME * speed;
    uv.x += twist * sin(time_angle * 4.0) * sin(dist * 10.0);
    uv.y += twist * cos(time_angle * 3.0) * cos(dist * 8.0);

    // 重新计算距离和角度（用于颜色分区）
    dist = length(uv);
    angle = atan(uv.y, uv.x);

    // 使用阶梯函数创建大色块
    // 方案1：基于角度分区
    float angle_step = floor(angle * 4.0 / (2.0 * 3.14159)) / 4.0;
    // 方案2：基于距离分区
    float dist_step = floor(dist * 5.0) / 5.0;

    // 混合两种分区产生复杂图案
    float pattern = fract(angle_step * 5.0 + dist_step * 3.0 + TIME * 0.5);

    // 根据pattern选择颜色
    vec3 final_color;
    if (pattern < 0.33) {
        final_color = color_a.rgb;
    } else if (pattern < 0.66) {
        final_color = color_b.rgb;
    } else {
        final_color = mix(color_a.rgb, color_b.rgb, 0.5);
    }

    // 边缘添加暗色或亮色
    float edge = smoothstep(radius * 0.8, radius, dist);
    final_color = mix(final_color, color_c.rgb, edge * 0.8);

    // 输出
    COLOR = vec4(final_color, alpha);
}