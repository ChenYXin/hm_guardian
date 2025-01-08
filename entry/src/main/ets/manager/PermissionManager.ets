import { abilityAccessCtrl, bundleManager, common, Permissions } from '@kit.AbilityKit';


class PermissionManager {
  atManager: abilityAccessCtrl.AtManager

  constructor() {
    this.atManager = abilityAccessCtrl.createAtManager()
  }

  //检查是否授权
  checkPermissions(permissions: Permissions[]) {
    //程序访问控制管理
    // const atManager = abilityAccessCtrl.createAtManager()
    //获取 bundle 信息
    const bundleInfo =
      bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
    //应用唯一吧标识，通过动态获取
    const accessTokenId = bundleInfo.appInfo.accessTokenId
    //检测权限是否授权，升级成遍历权限列表
    const grantStatus = permissions.map(item => this.atManager.checkAccessTokenSync(accessTokenId, item))
    // 返回权限组的检测结果，注意当前函数没有用到Promise，都是用Sync函数
    return grantStatus.every(v => v === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED)
  }

  //动态申请授权（首次弹窗申请）
  async requestPermissions(permissions: Permissions[]) {
    //创建应用权限管理器
    // const atManager = abilityAccessCtrl.createAtManager()
    // 向用户申请 user_grant 权限（温馨提示：首次申请时会弹窗，后续申请则不会再出现弹窗）
    const requestResult = await this.atManager.requestPermissionsFromUser(getContext(), permissions)
    //every 检查权限的是否都授权[0]
    const isAuth = requestResult.authResults.every(item => item === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED)
    //Promise.resolve() 返回 Promise成功，await 后续代码正常执行
    //Promise.reject()  返回 Promise错误，让await后续的代码不被执行，Promise.reject 可被catch捕获到
    return isAuth === true ? Promise.resolve(true) : Promise.reject(false)
  }

  //申请二次授权
  async requestPermissionOnSetting(permissions: Permissions[]) {
    //程序访问控制管理
    // const atManager = abilityAccessCtrl.createAtManager()
    const context = getContext() as common.UIAbilityContext
    const requestResult = await this.atManager.requestPermissionOnSetting(context, permissions)
    const isAuth = requestResult.every(item => item === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED)
    return isAuth === true ? Promise.resolve(true) : Promise.reject(false)
  }

  /**
   * 打开系统设置的权限管理页（处理授权结果）
   */
  openPermissionSettingsPage() {
    // 1. 获取应用上下文，并通过 as 断言收窄类型为 UIAbilityContext，否则 context 默认类型无法调用 startAbility 方法
    const context = getContext() as common.UIAbilityContext
    // 2. 获取 bundle 包信息
    const bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
    // 3. 通过 startAbility 打开 系统设置 页
    context.startAbility({
      bundleName: 'com.huawei.hmos.settings', // 固定写法CV：设置页的包名
      abilityName: 'com.huawei.hmos.settings.MainAbility', // 固定写法CV：设置页的 ability 名
      uri: 'application_info_entry', // 固定写法CV：打开 设置->应用和元服务
      parameters: {
        // 打开指定应用(包)的详情页面
        // pushParams: 'com.itheima.hm_guardian'
        // 应用包名可通过 bundleManager 动态获取
        pushParams: bundleInfo.name
      }
    })
  }
}

//导出 Manager
export const permissionManager = new PermissionManager()