Shader "Custom/Chapter7/c7_NormalMapTangentSpace"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1,1,1,1)
        _MainTex ("Main Tex", 2D) = "white" {}
        _BumpMap ("Normal Map", 2D) = "white" {}
        _BumpScale ("Bump Scale", Float) = 1.0
        _Specular ("Specular", Color) = (1,1,1,1)
        _Gloss ("Gloss", Range(8.0, 256))  = 20
    }
    SubShader
    {
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "UnityCG.cginc"
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent :TANGENT;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION；
                float2 uv : TEXCOORD0;
                float3 LightDir : TEXCOORD1;
                float3 ViewDir : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed3 Color;
            sampler2D _BumpMap;
            float4 _BumpScale;
            float _Gloss;
            fixed4 _Specular;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

                float3 binormal = cross( normalize(v.normal), normalize(v.tangent.xyz) ) * v.tangent.w;

                TANGENT_SPACE_ROTATION;
                o.LightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
                o.ViewDir = mul(rotation, OBjSpaceViewDir(v.vertex)).xyz;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 tangentLightDir = normalize(i.LightDir);
                fixed3 tangentViewDir = normalize(i.ViewDir);

                fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);
                fixed3 tangentNormal;

                tangentNormal = UnpackNormal(packedNormal);
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

                fixed3 halfDir = normalize(tangentNormal + tangentViewDir);

                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangent(tangentNormal, halfDir)), _Gloss));

                return (ambient + diffuse + specular, 1.0);
            }
            ENDCG
        }
    }

    FallBack "Specular"
}
