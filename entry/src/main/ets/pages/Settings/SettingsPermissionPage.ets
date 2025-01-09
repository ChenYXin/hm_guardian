import { Permissions } from '@kit.AbilityKit';
import { NavigationTitleBuilder } from '../../common/builders';
import { permissionManager, themeManager } from '../../manager';
import { promptAction } from '@kit.ArkUI';
import { it } from '@ohos/hypium';
import { notificationManager } from '@kit.NotificationKit';

interface PermissionItem {
  name: string
  title: string
  desc: string
  permissions: Permissions[]
  timeStamp: number // 用于更新授权状态
}

@Entry
@Component
struct SettingsPermissionPage {
  @State isNotificationEnabled: boolean = false
  @State permissionList: PermissionItem[] = [
    {
      name: 'notification',
      title: '通知',
      desc: '开启后可以获得安全播报，号码包升级等',
      permissions: [],
      timeStamp: 0
    },
    // 对所有应用开放的权限
    {
      name: 'camera',
      title: '相机',
      desc: '开启后才能使用安全扫码等功能',
      permissions: ['ohos.permission.CAMERA'],
      timeStamp: 0
    },
    {
      name: 'microphone',
      title: '麦克风',
      desc: '开启后才能录制加密视频和音频',
      permissions: ['ohos.permission.MICROPHONE'],
      timeStamp: 0
    },
    {
      name: 'calendar',
      title: '日历',
      desc: '开启后才能帮您清理诈骗日历、过期日历',
      permissions: ['ohos.permission.READ_CALENDAR', 'ohos.permission.WRITE_CALENDAR'],
      timeStamp: 0
    },
    {
      name: 'location',
      title: '位置',
      desc: '开启后精准显示空气指数，识别骚扰号码更加精准',
      permissions: ['ohos.permission.APPROXIMATELY_LOCATION', 'ohos.permission.LOCATION'],
      timeStamp: 0
    },
    // 允许ACL跨级别申请的权限
    {
      name: 'image_video',
      title: '照片',
      desc: '开启后才能帮您通过照片瘦身节省空间',
      permissions: ['ohos.permission.READ_IMAGEVIDEO', 'ohos.permission.WRITE_IMAGEVIDEO'],
      timeStamp: 0
    },
    {
      name: 'contacts',
      title: '通讯录',
      desc: '开启后才能帮您进行通讯录的备份、恢复和优化',
      permissions: ['ohos.permission.READ_CONTACTS', 'ohos.permission.WRITE_CONTACTS'],
      timeStamp: 0
    },
  ]

  onPageShow() {
    themeManager.settingStatusBarWhite()
    //页面显示，更新权限列表
    this.updatePermissions()
  }

  onPageHide() {
    themeManager.settingStatusBarBlack()
  }

  //申请权限
  async requestPermission(item: PermissionItem) {

    try {
      //申请权限
      await permissionManager.requestPermissions(item.permissions)
      // 允许 -> 变成文本

    } catch (error) {
      // 禁止 -> 申请二次弹窗 申请授权
      promptAction.showDialog({
        alignment: DialogAlignment.Center,
        title: '温馨提示',
        message: item.desc,
        buttons: [
          { text: '取消', color: $r('app.color.font_sub') },
          { text: '去设置', color: $r('app.color.brand') }
        ]
      }).then(async (res) => {
        if (res.index === 1) {
          try {
            //二次申请授权 - 成功
            await permissionManager.requestPermissionOnSetting(item.permissions)
            promptAction.showToast({ message: '权限申请通过' })

          } catch (error) {
            //二次申请授权 - 失败
            promptAction.showToast({ message: '权限申请不通过，功能受限' })
          } finally {
            this.updatePermissions()
          }
        }
      })
    } finally {
      this.updatePermissions()
    }
  }

  //更新权限列表
  updatePermissions() {
    this.permissionList = this.permissionList.map<PermissionItem>(item => {
      return {
        name: item.name,
        title: item.title,
        desc: item.desc,
        permissions: item.permissions,
        timeStamp: Date.now()
      }
    })
  }

  //关闭权限，注意：鸿蒙没有关闭权限的API，需要用户自行到设置页关闭
  closePermissions() {
    promptAction.showDialog({
      alignment: DialogAlignment.Center,
      title: '温馨提示',
      message: '关闭权限会影响应用的正常运行，您确认关闭吗?',
      buttons: [
        { text: '取消', color: $r('app.color.brand') },
        { text: '狠心关闭', color: $r('app.color.font_sub') }
      ]
    }).then(res => {
      //用户点击了 狠心关闭
      if (res.index === 1) {
        //通过代码打开当前应用的设置页
        permissionManager.openPermissionSettingsPage()
      }
    })
  }

  // 申请通知授权
  async requestNotification() {
    try {
      // 经验：鸿蒙返回值为 Promise<void> 的 API ，一般是通过 try catch 捕获错误，鼠标悬停到 API 上可看到 错误编码 和 错误说明
      await notificationManager.requestEnableNotification()
    } catch (error) {
      //   禁止 -> 引导用户打开设置页开启权限
      // 如果禁止授权，先弹窗询问，用户点击按钮后打开设置页
      promptAction.showDialog({
        alignment: DialogAlignment.Center,
        title: '温馨提示',
        message: '建议开启通知权限，以提供更好的体验',
        buttons: [
          { text: '取消', color: $r('app.color.font_sub') },
          { text: '去设置', color: $r('app.color.brand') },
        ]
      })
        .then((res) => {
          // 用户点击了去设置
          if (res.index === 1) {
            // 通过代码打开当前应用的设置页
            permissionManager.openPermissionSettingsPage()
          }
        })
    }
    // 更新通知权限
    this.updateNotification()
    // 主动触发列表更新，更新所有的列表按钮状态
    this.updatePermissions()
  }

  // 刷新通知权限
  async updateNotification() {
    // 查询通知是否授权
    this.isNotificationEnabled = await notificationManager.isNotificationEnabled()
  }

  build() {
    Navigation() {
      Row() {
        Text('建议您开启全部权限\n体验小卫更精准、更贴心的功能！')
          .fontSize(14)
          .fontColor($r('app.color.white'))
          .lineHeight(20)
          .textAlign(TextAlign.Center)
      }
      .height(180 - 56)

      Column() {
        ForEach(this.permissionList, (item: PermissionItem) => {
          Row() {
            Column({ space: 5 }) {
              Text(item.title)
                .fontSize(16)
                .fontWeight(500)
                .fontColor($r('app.color.font'))
              Text(item.desc)
                .fontSize(12)
                .fontColor($r('app.color.font_sub'))
            }
            .alignItems(HorizontalAlign.Start)

            // 通知
            if (item.name === 'notification') {
              // 是否已开启权限
              if (this.isNotificationEnabled) {
                Text('已开启')
                  .fontSize(14)
                  .fontColor($r('app.color.brand'))
              } else {
                Toggle({ type: ToggleType.Switch, isOn: false })
                  .onChange(async () => {
                    // 申请通知权限
                    this.requestNotification()
                  })
              }
            } else {
              //检测权限是否开启
              if (permissionManager.checkPermissions(item.permissions)) {
                // if (false) {
                Text('已开启')
                  .fontSize(14)
                  .fontColor($r('app.color.brand'))
              } else {
                Toggle({ type: ToggleType.Switch, isOn: false })
                  .onChange(async () => {
                    //点击申请 user_grant 授权
                    this.requestPermission(item)
                  })
              }
            }
          }
          .width('100%')
          .height(64)
          .justifyContent(FlexAlign.SpaceBetween)
        })
        Button('关闭权限')
          .fontColor($r('app.color.font_sub'))
          .backgroundColor(Color.Transparent)
          .margin({ top: 20 })
          .onClick(() => {
            //关闭权限，弹窗提示，关闭权限需到设置页关闭
            // permissionManager.openPermissionSettingsPage()
            this.closePermissions()
          })
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 20, right: 20 })
      .backgroundColor($r('app.color.white'))
    }
    .title(NavigationTitleBuilder('权限管理'))
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .hideBackButton(true)
    .linearGradient({
      angle: 180,
      colors: [[$r('app.color.brand'), 0], [$r('app.color.brand_light'), 0.25], [$r('app.color.white'), 0.25]]
    })
  }
}