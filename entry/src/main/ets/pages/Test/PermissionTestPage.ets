import { abilityAccessCtrl, bundleManager, common } from '@kit.AbilityKit';
import { JSON } from '@kit.ArkTS';
import { themeManager, permissionManager } from '../../manager';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct PermissionTestPage {
  aboutToAppear(): void {
    themeManager.enableFullScreen()
    permissionManager.checkPermissions([])
  }

  build() {
    Navigation() {
      Scroll() {
        Column({ space: 10 }) {
          Button('检测权限')
            .onClick(() => {
              //程序访问控制管理
              const atManager = abilityAccessCtrl.createAtManager()
              //获取 bundle 信息
              const bundleInfo =
                bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
              //应用唯一吧标识，通过动态获取
              const accessTokenId = bundleInfo.appInfo.accessTokenId
              //检测权限
              const grantStatus = atManager.checkAccessTokenSync(accessTokenId, 'ohos.permission.READ_CALENDAR')
              AlertDialog.show({
                message: JSON.stringify(grantStatus, null, 2)
              })
            })
          Button('动态向用户申请授权')
            .onClick(async () => {
              //程序访问控制管理
              const atManager = abilityAccessCtrl.createAtManager()
              const result = await atManager.requestPermissionsFromUser(getContext(), ['ohos.permission.READ_CALENDAR'])
              AlertDialog.show({
                message: JSON.stringify(result, null, 2)
              })
            })

          //二次向用户申请授权
          Button('打开设置页(用于处理授权失败的情况）')
            .onClick(async () => {
              //程序访问控制管理
              const atManager = abilityAccessCtrl.createAtManager()
              const context = getContext() as common.UIAbilityContext
              const result = await atManager.requestPermissionOnSetting(context, ['ohos.permission.READ_CALENDAR'])
              AlertDialog.show({
                message: JSON.stringify(result, null, 2)
              })
            })

          Divider().strokeWidth(1)

          Button('检查权限是否授权')
            .onClick(() => {
              const isAuth =
                permissionManager.checkPermissions(['ohos.permission.CAMERA', 'ohos.permission.WRITE_CONTACTS'])
              AlertDialog.show({
                message: JSON.stringify(isAuth, null, 2)
              })
            })
          Button('动态申请权限')
            .onClick(async () => {
              const isAuth =
                await permissionManager.requestPermissions(['ohos.permission.CAMERA', 'ohos.permission.WRITE_CONTACTS'])
              promptAction.showToast({ message: '能否调用权限' + isAuth })
              //权限允许后，后续就能调用相机的API了
              AlertDialog.show({ message: '现在调用相机的API拉' })
            })
          Button('二次申请授权')
            .onClick(async () => {
              const isAuth = await permissionManager.requestPermissionOnSetting(['ohos.permission.CAMERA',
                'ohos.permission.WRITE_CONTACTS'])
              promptAction.showToast({ message: '能否调用权限' + isAuth })
              //权限允许后，后续就能调用相机的API了
              AlertDialog.show({ message: '现在调用相机的API拉' })
            })

          Text('当前CAMERA权限为：' + permissionManager.checkPermissions(['ohos.permission.CAMERA']))
        }
        .constraintSize({ minHeight: '100%' })
      }
      .width('100%')
      .height('100%')
    }
    .title('权限学习')
    .titleMode(NavigationTitleMode.Mini)
  }
}