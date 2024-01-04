/*
 * WiVRn VR streaming
 * Copyright (C) 2022  Guillaume Meunier <guillaume.meunier@centraliens.net>
 * Copyright (C) 2022  Patrick Nicolas <patricknicolas@laposte.net>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#version 450

#define NB_TEXCOORDS 2

layout(set = 0, binding = 0) uniform scene_ubo
{
	mat4 view;
	mat4 proj;
	vec4 light_position;
	vec4 ambient_color;
	vec4 light_color;
} scene;

layout(set = 0, binding = 1) uniform mesh_ubo
{
	mat4 model;
	mat4 modelview;
	mat4 modelviewproj;
} mesh;

#ifdef FRAG_SHADER
layout(set = 1, binding = 0) uniform sampler2D base_color;
layout(set = 1, binding = 1) uniform sampler2D metallic_roughness;
layout(set = 1, binding = 2) uniform sampler2D occlusion;
layout(set = 1, binding = 3) uniform sampler2D emissive;
layout(set = 1, binding = 4) uniform sampler2D normal_map;
layout(set = 1, binding = 5) uniform material_ubo
{
	vec4 base_color_factor;
	vec4 base_emissive_factor;
	float metallic_factor;
	float roughness_factor;
	float occlusion_strength;
	float normal_scale;

	int base_color_texcoord;
	int metallic_roughness_texcoord;
	int occlusion_texcoord;
	int emissive_texcoord;
	int normal_texcoord;
} material;
#endif

// Vertex input
#ifdef VERT_SHADER
layout(location = 0) in vec3 in_position;
layout(location = 1) in vec3 in_normal;
layout(location = 2) in vec3 in_tangent;
layout(location = 3) in vec2 in_texcoord[NB_TEXCOORDS];
layout(location = 3+NB_TEXCOORDS) in vec4 in_color;
layout(location = 4+NB_TEXCOORDS) in vec4 in_joints;
layout(location = 5+NB_TEXCOORDS) in vec4 in_weights;
#endif

// Vertex-to-fragment
#ifdef VERT_SHADER
#define VERT_TO_FRAG out
#else
#define VERT_TO_FRAG in
#endif

layout(location = 0) VERT_TO_FRAG vec3 normal;
layout(location = 1) VERT_TO_FRAG vec2 texcoord[NB_TEXCOORDS];
layout(location = 1+NB_TEXCOORDS) VERT_TO_FRAG vec3 frag_pos;
layout(location = 2+NB_TEXCOORDS) VERT_TO_FRAG vec4 light_pos;

// Fragment output
#ifdef FRAG_SHADER
layout(location = 0) out vec4 out_color;
#endif

// Shader code
#ifdef VERT_SHADER
void main()
{
	normal = vec3(mesh.modelview * vec4(in_normal, 0.0));

	for(int i = 0; i < 2; i++)
		texcoord[i] = in_texcoord[i];

	gl_Position = mesh.modelviewproj * vec4(in_position, 1.0);
	frag_pos = vec3(mesh.modelview * vec4(in_position, 1.0));
	light_pos = mesh.modelview * scene.light_position;
}

#endif

#ifdef FRAG_SHADER
void main()
{
	vec3 light_dir = normalize(light_pos.xyz - frag_pos * light_pos.w);
	vec3 view_dir = normalize(frag_pos);
	vec3 normal_unit = normalize(normal);
	vec3 reflect_dir = reflect(-light_dir, normal_unit);

	// Ambient lighting
	vec3 ambient = vec3(scene.ambient_color);

	// Diffuse lighting
	vec3 diffuse = max(dot(normal_unit, light_dir), 0.0) * vec3(scene.light_color);

	// Specular lighting
// 	vec3 half_dir = normalize(light_dir + view_dir);
// 	float spec_angle = max(dot(half_dir, normal_unit), 0.0);
// 	vec3 specular = pow(spec_angle, instance.specular_power) * instance.specular_strength * instance.light_color;

	vec3 light = ambient + diffuse /*+ specular*/;
// 	out_color = texture(base_color, texcoord[0]) * vec4(light, 1.0);

// 	out_color = vec4(1.0, 1.0, 1.0, 1.0);
	out_color = texture(base_color, texcoord[0]);
}
#endif
