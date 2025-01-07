import { router } from '@kit.ArkUI'
import { LOGIN_INFO, LoginInfoResponse } from '../../common/constants'
import deviceInfo from '@ohos.deviceInfo'
import { hidebug } from '@kit.PerformanceAnalysisKit'
import { statfs } from '@kit.CoreFileKit'
import { common } from '@kit.AbilityKit';
import { batteryInfo } from '@kit.BasicServicesKit'

interface UsageItem {
  icon: Resource
  name: string
  value: string
  unit: string
}

@Component
export struct MyTabsComp {
  // 用户信息持久化
  @StorageLink(LOGIN_INFO) loginInfo: LoginInfoResponse = {}
  @StorageLink('topHeight') topHeight: number = 0
  // @Provide 装饰器和 @Consume 装饰器：与后代组件双向同步
  @Consume @Watch('onTabsChange') currentIndex: number
  @Consume @Watch('onTabsChange') isPageShow: boolean
  //设备名称
  @State deviceName: string = ''
  //电量百分比
  @State batteryState: number = 0
  //内存占用率
  @State memorySize: number = 0
  //CPU占用率
  @State cpuUsage: number = 0
  @State statfsFreeSize: number = 0

  aboutToAppear(): void {
    this.getDeDeviceInfo()
    this.getDebugInfo()
    this.getStatfsInfo()
    this.getBatteryInfo()
  }

  //当Tabs发生变化时
  onTabsChange() {
    if (this.currentIndex === 2 && this.isPageShow === true) {
      this.getDebugInfo()
      this.getStatfsInfo()
      this.getBatteryInfo()
    }
  }

  //获取设备产品名称
  getDeDeviceInfo() {
    // AlertDialog.show({
    //   message: deviceInfo.marketName
    // })
    this.deviceName = deviceInfo.marketName
  }

  //以同步方法获取指定文件系统空闲字节数
  getStatfsInfo() {
    let context = getContext()
    // 单位 byte
    // 1000MB = 1GB
    // 1000KB = 1MB
    // 1000B = 1KB
    this.statfsFreeSize = statfs.getFreeSizeSync(context.filesDir) / 1000 / 1000 / 1000

  }

  //获取调试信息，CPU占用率、内存
  getDebugInfo() {
    this.cpuUsage = hidebug.getCpuUsage() * 100
    //获取应用进程实际使用的物理内存大小，单位为kb
    //1MB =1024KB (Windows 系统)
    //1MB =1000KB (Mac 系统,Linux 系统,手机 系统, U盘，DVD 光盘)
    this.memorySize = Number(hidebug.getPss()) / 1000
  }

  //获取电量信息
  getBatteryInfo() {
    //当前设备剩余电池电量百分比
    this.batteryState = batteryInfo.batterySOC
  }

  // 标题行
  @Builder
  TitleRow(title = '', target = '') {
    Row() {
      Text(title)
        .fontSize(18)
        .fontWeight(500)
        .fontColor($r('app.color.font'))
      Navigator({ target: target }) {
        Row({ space: 2 }) {
          Text('查看')
            .fontColor($r('app.color.font_sub'))
            .fontSize(14)
          Image($r('app.media.ic_public_arrow_right'))
            .width(12)
            .fillColor('#89939C')
        }
      }
      .visibility(target ? Visibility.Visible : Visibility.None)
    }
    .width('100%')
    .padding({ top: 40, bottom: 20 })
    .justifyContent(FlexAlign.SpaceBetween)
  }

  // 占用率
  @Builder
  UsageColumn(item: UsageItem) {
    Column({ space: 10 }) {
      Image(item.icon)
        .height(28)
        .aspectRatio(1)
      Text(item.name)
        .fontSize(14)
        .fontColor($r('app.color.font2'))
      Text() {
        Span(item.value)
          .fontSize(26)
          .fontWeight(500)
        Span(' ')
        Span(item.unit)
      }
      .fontSize(14)
      .fontColor($r('app.color.font'))
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .height(120)
    .borderRadius(5)
    .padding(10)
    .backgroundColor($r('app.color.background'))
  }

  build() {
    Scroll() {
      Column() {
        Stack({ alignContent: Alignment.TopEnd }) {
          // 设置按钮
          Image($r('app.media.ic_my_settings'))
            .width(22)
            .aspectRatio(1)
            .zIndex(1)
            .onClick(() => {
              router.pushUrl({ url: 'pages/Settings/SettingsIndexPage' })
            })
            .margin({ top: this.topHeight + 25, right: 25 })
          // 用户信息
          Column() {
            if (this.loginInfo.accessToken) {
              // 已登录
              Column({ space: 10 }) {
                Image(this.loginInfo.avatar || $r("app.media.ic_my_avatar_default"))
                  .height(70)
                  .aspectRatio(1)
                  .borderRadius(70 / 2)
                Text(this.loginInfo.nickname)
                  .fontSize(18)
                  .fontWeight(500)
                  .fontColor($r('app.color.font'))
              }
              .onClick(() => {
                router.pushUrl({ url: 'pages/User/UserInfoPage' })
              })
            } else {
              // 未登录
              Column({ space: 10 }) {
                Image($r("app.media.ic_my_avatar_default"))
                  .height(70)
                  .aspectRatio(1)
                  .borderRadius(70 / 2)
                Text('用户登录')
                  .fontSize(18)
                  .fontWeight(500)
                  .fontColor($r('app.color.font'))
              }
              .onClick(() => {
                router.pushUrl({ url: 'pages/User/UserLoginPage' })
              })
            }
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ top: 56 })
        }
        .height(250)
        .width('100%')

        // 硬件信息
        Column() {
          this.TitleRow(this.deviceName, 'pages/Hardware/HardwareIndexPage')
          GridRow({ columns: 3, gutter: 10 }) {
            GridCol() {
              this.UsageColumn({
                icon: $r('app.media.ic_my_cpu'),
                name: 'CPU占用',
                value: this.cpuUsage.toFixed(0),
                unit: '%'
              })
            }
            .onClick(() => {
              router.pushUrl({ url: 'pages/Hardware/HardwareIndexPage' })
            })

            GridCol() {
              this.UsageColumn({
                icon: $r('app.media.ic_my_ram'),
                name: '内存占用',
                value: this.memorySize.toFixed(0),
                unit: 'M'
              })
            }
            .onClick(() => {
              router.pushUrl({ url: 'pages/Hardware/HardwareIndexPage' })
            })

            GridCol() {
              this.UsageColumn({
                icon: $r('app.media.ic_my_storage'),
                name: '剩余存储',
                //0: 不保留小数位, 1:保留1位
                value: this.statfsFreeSize.toFixed(1),
                unit: 'GB'
              })
            }
            .onClick(() => {
              router.pushUrl({ url: 'pages/Hardware/HardwareIndexPage' })
            })
          }
        }
        .padding({ left: 20, right: 20 })

        // 电池管家
        Column() {
          this.TitleRow('电池管家', 'pages/Battery/BatteryIndexPage')
          Column() {
            Row() {
              Text(`电池剩余${this.batteryState}%`)
                .fontSize(14)
                .fontColor($r('app.color.font2'))
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)

            // 环形图表
            Gauge({ value: this.batteryState, min: 0, max: 100 }) {
              Column() {
                Text(this.batteryState + '%')
                  .fontSize(30)
                  .fontWeight(500)
                  .margin({ top: 60 })
              }
              .width('100%')
              .height('100%')
            }
            .startAngle(270)
            .endAngle(90)
            .description(null)
            .colors(new LinearGradient([
              { color: $r('app.color.danger'), offset: 0 },
              { color: $r('app.color.warning'), offset: 0.2 },
              { color: $r('app.color.success'), offset: 1 },
            ]))
            .strokeWidth(12)
            .width(200)
            .height(200)
            .margin({ top: 20 })
          }
          .width('100%')
          .height(180)
          .borderRadius(6)
          .padding(15)
          .backgroundColor($r('app.color.background'))
          .onClick(() => {
            router.pushUrl({ url: 'pages/Battery/BatteryIndexPage' })
          })
        }
        .padding({ left: 20, right: 20 })
      }
      .constraintSize({ minHeight: '100%' })
    }
    .backgroundImage('/common/images/MyPage_bg.png')
    .backgroundImageSize({ width: '100%' })
    .height('100%')
  }
}