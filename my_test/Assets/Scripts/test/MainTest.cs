#if !XLUA_GENERAL
using UnityEngine;
using System.Collections;
using XLua;

public class MainTest : MonoBehaviour
{
	LuaEnv luaenv;
	// Use this for initialization
	void Start()
	{
		luaenv = LuaEnvSingleton.Instance;
		luaenv.DoString("require 'lua.DreamGarden.main'");
	}

	// Update is called once per frame
	void Update()
	{
		luaenv.GC();
	}
}
#endif



public class LuaEnvSingleton
{

	static private LuaEnv instance = null;
	static public LuaEnv Instance
	{
		get
		{
			if (instance == null)
			{
				instance = new LuaEnv();
#if XLUA_GENERAL
                instance.DoString("package.path = package.path..';../Test/UnitTest/xLuaTest/CSharpCallLua/Resources/?.lua.txt;../Test/UnitTest/StreamingAssets/?.lua'");
#endif
			}

			return instance;
		}
	}
}