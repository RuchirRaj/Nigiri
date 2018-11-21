﻿Shader "Hidden/Nigiri_Blit_Position_LastCameraDepthTexture"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 5.0
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float4 worldPos : TEXCOORD2;
			};

			float4x4	InverseProjectionMatrix;
			float4x4	InverseViewMatrix;

			float worldVolumeBoundary;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;

				o.worldPos = mul(unity_ObjectToWorld, v.vertex);

				return o;
			}
			
			sampler2D _MainTex;
			sampler2D _LastCameraDepthTexture;
			sampler2D _CameraDepthTexture;
			sampler2D orthoDepth;
			uniform RWStructuredBuffer<float4> positionBuffer : register(u6);

			float3 rgb2hsv(float3 c)
			{
				float4 k = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
				float4 p = lerp(float4(c.bg, k.wz), float4(c.gb, k.xy), step(c.b, c.g));
				float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

				float d = q.x - min(q.w, q.y);
				float e = 1.0e-10;

				return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
			}

			float3 hsv2rgb(float3 c)
			{
				float4 k = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
				float3 p = abs(frac(c.xxx + k.xyz) * 6.0 - k.www);
				return c.z * lerp(k.xxx, saturate(p - k.xxx), c.y);
			}

			float4 DecodeRGBAuint(uint value)
			{
				uint ai = value & 0x0000007F;
				uint vi = (value / 0x00000080) & 0x000007FF;
				uint si = (value / 0x00040000) & 0x0000007F;
				uint hi = value / 0x02000000;

				float h = float(hi) / 127.0;
				float s = float(si) / 127.0;
				float v = (float(vi) / 2047.0) * 10.0;
				float a = ai * 2.0;

				v = pow(v, 3.0);

				float3 color = hsv2rgb(float3(h, s, v));

				return float4(color.rgb, a);
			}

			uint EncodeRGBAuint(float4 color)
			{
				//7[HHHHHHH] 7[SSSSSSS] 11[VVVVVVVVVVV] 7[AAAAAAAA]
				float3 hsv = rgb2hsv(color.rgb);
				hsv.z = pow(hsv.z, 1.0 / 3.0);

				uint result = 0;

				uint a = min(127, uint(color.a / 2.0));
				uint v = min(2047, uint((hsv.z / 10.0) * 2047));
				uint s = uint(hsv.y * 127);
				uint h = uint(hsv.x * 127);

				result += a;
				result += v * 0x00000080; // << 7
				result += s * 0x00040000; // << 18
				result += h * 0x02000000; // << 25

				return result;
			}

			uint twoD2oneD(float2 coord)
			{
				return coord.x + 1024 * coord.y;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				/*half3 color = tex2D(_MainTex, i.uv).rgb;

				// read low res depth and reconstruct world position
				float depth = SAMPLE_DEPTH_TEXTURE(orthoDepth, i.uv);

				//linearise depth		
				float lindepth = Linear01Depth(depth);

				//get view and then world positions		
				float4 viewPos = float4(i.cameraRay.xyz * lindepth, 1.0f);
				float3 worldPos = mul(InverseViewMatrix, viewPos).xyz;
				
				return float4(worldPos, lindepth);*/

				return positionBuffer[twoD2oneD(i.uv.xy)];

			}
			ENDCG
		}
	}
}
