
A=aap-lv2-natives/prefab/modules/all

rm -rf $A/include/
rm -rf $A/libs/android.*/lib/

cp -R ../dist/x86/include $A

cp -R ../dist/armeabi-v7a/lib $A/libs/android.armeabi-v7a/
cp -R ../dist/arm64-v8a/lib   $A/libs/android.arm64-v8a/
cp -R ../dist/x86/lib         $A/libs/android.x86/
cp -R ../dist/x86_64/lib      $A/libs/android.x86_64/

cd aap-lv2-natives && zip -r aap-lv2-natives.aar * && cd ..
