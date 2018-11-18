﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[ImageEffectAllowedInSceneView]
public class Nigiri_EmissiveCameraHelper : MonoBehaviour {
   
    public static Camera cam;

    public static Shader emissiveShader;

    public static RenderTexture lightingTexture;
    
    public static ComputeBuffer lightMapBuffer;

    public ComputeShader clearComputeCache;

    public static Vector2Int injectionResolution;

    private void OnEnable()
    {
        StartCoroutine(DoEnable());
    }

    IEnumerator<int> DoEnable ()
    {
        while (injectionResolution.x == 0)
        {
            yield return 0;
        }

        emissiveShader = Shader.Find("Hidden/Nigiri_Injection");

        clearComputeCache = Resources.Load("SEGIClear_Cache") as ComputeShader;

        cam = GetComponent<Camera>();

        lightingTexture = new RenderTexture(256, 256, 0, RenderTextureFormat.ARGBFloat);
        lightingTexture.Create();

        lightMapBuffer = new ComputeBuffer(256 * 256 * 256, sizeof(uint), ComputeBufferType.Default);

        cam.depthTextureMode = DepthTextureMode.None;
        cam.clearFlags = CameraClearFlags.Color;
        cam.useOcclusionCulling = false;
        cam.backgroundColor = Color.black;
        cam.renderingPath = RenderingPath.Forward;
        cam.orthographic = true;
        cam.allowHDR = true;
        cam.allowMSAA = false;
        cam.depth = -2;
    }

    private void OnDisable()
    {
        if (lightingTexture != null) lightingTexture.Release();
        if (lightMapBuffer != null) lightMapBuffer.Release();
    }

    public static void DoRender()
    {
        if (lightingTexture != null && lightMapBuffer != null)
        {
            Graphics.SetRandomWriteTarget(5, lightMapBuffer);
            cam.targetTexture = lightingTexture;
            cam.RenderWithShader(emissiveShader, "");
        }
    }
}