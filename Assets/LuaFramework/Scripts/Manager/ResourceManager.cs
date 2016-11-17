using UnityEngine;
using System.Collections;
using System.IO;
using System;

namespace LuaFramework {
    public class ResourceManager : Manager {
        private AssetBundle shared;

        /// <summary>
        /// ³õÊ¼»¯
        /// </summary>
        public void initialize(Action func) {
            if (AppConst.ExampleMode) {
                //------------------------------------Shared--------------------------------------
                string uri = Util.DataPath + "shared" + AppConst.ExtName;
                Debug.LogWarning("LoadFile::>> " + uri);

                shared = AssetBundle.LoadFromFile(uri);
#if UNITY_5
                shared.LoadAsset("Dialog", typeof(GameObject));
#else
                shared.Load("Dialog", typeof(GameObject));
#endif
            }
            if (func != null) func();    //×ÊÔ´³õÊ¼»¯Íê³É£¬»Øµ÷ÓÎÏ·¹ÜÀíÆ÷£¬Ö´ÐÐºóÐø²Ù×÷ 
        }

        /// <summary>
        /// ÔØÈëËØ²Ä
        /// </summary>
        public AssetBundle LoadBundle(string name) {
            string uri = Util.DataPath + name.ToLower() + AppConst.ExtName;
            AssetBundle bundle = AssetBundle.LoadFromFile(uri); //¹ØÁªÊý¾ÝµÄËØ²Ä°ó¶¨
            return bundle;
        }

        /// <summary>
        /// Ïú»Ù×ÊÔ´
        /// </summary>
        void OnDestroy() {
            if (shared != null) shared.Unload(true);
            Debug.Log("~ResourceManager was destroy!");
        }
    }
}