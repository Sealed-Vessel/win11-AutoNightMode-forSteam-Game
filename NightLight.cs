using System;
using System.Collections.Generic;
using System.IO;
using Microsoft.Win32;

public static class NightLight {
    const string Key = @"Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\DefaultAccount\Current\default$windows.data.bluelightreduction.bluelightreductionstate\windows.data.bluelightreduction.bluelightreductionstate";
    static void Expect(byte[] b, ref int p, params byte[] values) {
        foreach(byte v in values) if(p >= b.Length || b[p++] != v) throw new InvalidDataException("Unsupported Night Light format. No changes made.");
    }
    static ulong Read(byte[] b, ref int p) {
        ulong n=0; for(int s=0;s<64;s+=7) { if(p>=b.Length) throw new InvalidDataException(); byte v=b[p++]; if(s==63 && v>1) throw new InvalidDataException(); n|=(ulong)(v&127)<<s; if(v<128)return n; } throw new InvalidDataException();
    }
    static void Write(List<byte> b, ulong n) { while(n>127){b.Add((byte)((n&127)|128));n>>=7;}b.Add((byte)n); }
    public static byte[] Transform(byte[] b, bool active, out bool old) {
        int p=0; Expect(b,ref p,67,66,1,0,10,2,1,0,42,6); ulong timestamp=Read(b,ref p);
        Expect(b,ref p,42,43,14); ulong length=Read(b,ref p); int start=p;
        Expect(b,ref p,67,66,1,0); old=false;
        if(p<b.Length && b[p]==16){Expect(b,ref p,16,0);old=true;}
        if(p<b.Length && b[p]==208){Expect(b,ref p,208,10); ulong cause=Read(b,ref p); if(cause>2)throw new InvalidDataException();}
        if(p<b.Length && b[p]==198){Expect(b,ref p,198,20);Read(b,ref p);}
        if(p<b.Length && b[p]==194) throw new InvalidDataException("Night Light is unavailable on this display.");
        Expect(b,ref p,0); if((ulong)(p-start)!=length)throw new InvalidDataException();
        Expect(b,ref p,0,0,0); if(p!=b.Length)throw new InvalidDataException();
        if(old==active)return b;
        var inner=new List<byte>(new byte[]{67,66,1,0});
        if(active)inner.AddRange(new byte[]{16,0});
        inner.AddRange(new byte[]{208,10,2,198,20});Write(inner,(ulong)DateTime.UtcNow.ToFileTimeUtc());inner.Add(0);
        var result=new List<byte>(new byte[]{67,66,1,0,10,2,1,0,42,6});
        ulong now=(ulong)(DateTime.UtcNow-new DateTime(1970,1,1)).TotalSeconds;
        Write(result,Math.Max(now,checked(timestamp+2)));result.AddRange(new byte[]{42,43,14});Write(result,(ulong)inner.Count);result.AddRange(inner);result.AddRange(new byte[]{0,0,0});return result.ToArray();
    }
    public static bool Get() {
        using(var k=Registry.CurrentUser.OpenSubKey(Key)) { if(k==null || k.GetValue("Data")==null)throw new InvalidOperationException("NIGHTLIGHT_MISSING"); bool old;Transform((byte[])k.GetValue("Data"),false,out old);return old; }
    }
    public static void Set(bool active) {
        using(var k=Registry.CurrentUser.OpenSubKey(Key,true)) {
            if(k==null)throw new InvalidOperationException("Night Light registry is missing.");
            bool old;byte[] data=Transform((byte[])k.GetValue("Data"),active,out old);
            if(old!=active)k.SetValue("Data",data,RegistryValueKind.Binary);
        }
    }
}
