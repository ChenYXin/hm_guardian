import { NavigationTitleBuilder } from '../../common/builders';
import { SENSOR_NAME_LIST, SensorName } from '../../common/constants';
import { themeManager } from '../../manager';
import { deviceInfo } from '@kit.BasicServicesKit';
import { process } from '@kit.ArkTS';
//导入 dayjs 核心包
// import dayjs from 'dayjs'
//导入 dayjs 插件（相对时间 - 运行时间）
// import duration from 'dayjs/plugin/duration'

//注册 dayjs 插件（相对时间 - 运行时间）
// dayjs.extend(duration)
import { formatToDateTime, formatToDate } from '../../common/utils/date'
import { connection } from '@kit.NetworkKit';
import { display } from '@kit.ArkUI';
import { sensor } from '@kit.SensorServiceKit';

/**
 * 计算子网掩码
 * @param prefixLength 前缀长度
 * @returns 子网掩码字符串
 */
function calculateSubnetMask(prefixLength: number): string {
  // 计算每个字节的子网掩码部分
  let subnetMask = '';
  for (let i = 0; i < 4; i++) {
    // 每个字节中的有效位数
    const bits = Math.min(prefixLength, 8);
    // 计算子网掩码字节的值并添加到结果字符串
    subnetMask += (256 - Math.pow(2, 8 - bits)) + '.';
    // 更新剩余的位数
    prefixLength -= bits;
  }
  // 去除末尾的点并返回子网掩码字符串
  return subnetMask.slice(0, -1);
}

/**
 * 计算广播地址
 * @param ipAddress IP地址字符串，例如 "192.168.2.13"
 * @param subnetMask 子网掩码字符串，例如 "255.255.255.0"
 * @returns 广播地址字符串
 */
function calculateBroadcastAddress(ipAddress: string, subnetMask: string): string {
  // 将IP地址字符串转换为数字数组
  const ipParts: number[] = ipAddress.split('.')
    .map(Number);
  // 将子网掩码字符串转换为数字数组
  const subnetParts: number[] = subnetMask.split('.')
    .map(Number);
  // 计算每个字节的广播地址部分
  const broadcastParts: number[] = [];
  for (let i = 0; i < 4; i++) {
    // 计算每个字节的广播地址值并添加到结果数组
    broadcastParts.push(ipParts[i] | (255 - subnetParts[i]));
  }
  // 将结果数组转换为字符串并使用点分隔
  return broadcastParts.join('.');
}


@Entry
@Component
struct HardwareIndexPage {
  // 产品名称
  @State marketName: string = '-'
  // 系统版本
  @State osFullName: string = '-'
  // 系统软件API版本
  @State sdkApiVersion: string = '-'
  // 设备类型
  @State deviceType: string = '-'
  // 获取当前系统已运行的秒数
  @State uptime: number = 0
  // 网络类型
  @State netBearType: string = '-'
  // IP 地址
  @State IPAddress: string = '0.0.0.0'
  // 子网掩码
  @State subnetMask: string = '0.0.0.0'
  // 广播地址
  @State broadcastAddress: string = '0.0.0.0'
  // 屏幕分辨率（像素）
  @State displayHeight: number = 0
  @State displayWidth: number = 0
  // 屏幕刷新率（Hz）
  @State displayRefreshRate: number = 0
  // 像素密度（PPI）
  @State displayDensityDPI: number = 0
  // 支持的传感器id列表
  @State supportSensorIds: number[] = []

  onPageShow() {
    themeManager.settingStatusBarWhite()
  }

  onPageHide() {
    themeManager.settingStatusBarBlack()
  }

  aboutToAppear(): void {
    this.getDeviceInfo()
    this.getProcessInfo()
    this.getConnectInfo()
    this.getDisplayInfo()
    this.getSensorInfo()
  }

  getDeviceInfo() {
    //产品名称，可用于区分 模拟器（emulator）、真机（产品型号）
    this.marketName = deviceInfo.marketName
    //系统版本
    this.osFullName = deviceInfo.osFullName
    //系统软件api版本（API 9，11，12，13等）
    this.sdkApiVersion = deviceInfo.sdkApiVersion.toString()
    //设备类型，可用于区分 手机、平板、PC、车机、手表、电视 等
    this.deviceType = deviceInfo.deviceType
  }

  //获取进程相关的信息
  getProcessInfo() {
    //获取当前系统已运行的秒数
    this.uptime = process.uptime()
  }

  //获取网络信息
  getConnectInfo() {
    //获取检查默认数据网络是否激活
    const isHasDefaultNet = connection.hasDefaultNetSync()
    if (isHasDefaultNet === true) {
      // this.netBearType = '有网络'
      //有网络的情况下，判断是什么网络
      this.getNetBearType()
      //获取IP地址
      this.getProperties()
    } else {
      this.netBearType = '无网络'
    }
  }

  //获取网络类型（以太网、WIFI、蜂窝）
  getNetBearType() {
    //获取默认激活的数据网络
    const netHandle = connection.getDefaultNetSync()
    //获取网络的连接信息
    const netCapabilities = connection.getNetCapabilitiesSync(netHandle)
    if (netCapabilities.bearerTypes.includes(connection.NetBearType.BEARER_ETHERNET)) {
      this.netBearType = '以太网网络' //网线
    } else if (netCapabilities.bearerTypes.includes(connection.NetBearType.BEARER_WIFI)) {
      this.netBearType = 'WIFI网络' //WIFI
    } else if (netCapabilities.bearerTypes.includes(connection.NetBearType.BEARER_CELLULAR)) {
      this.netBearType = '蜂窝网络' //流量蜂窝
    } else {
      this.netBearType = '未知网络'
    }
  }

  //获取网络连接信息（ IP 地址）
  getProperties() {
    //获取默认激活的数据网络
    const netHandle = connection.getDefaultNetSync()
    //获取网络的连接信息
    const connectionProperties = connection.getConnectionPropertiesSync(netHandle)
    //提取链路信息
    const linkAddress = connectionProperties.linkAddresses[0]
    if (linkAddress) {
      //提取IP地址
      this.IPAddress = linkAddress.address.address
      // 计算子网掩码（了解）
      this.subnetMask = calculateSubnetMask(linkAddress.prefixLength)
      // 计算广播地址（了解）
      this.broadcastAddress = calculateBroadcastAddress(this.IPAddress, this.subnetMask)
    }
  }

  //获取屏幕属性
  getDisplayInfo() {
    const defaultDisplay = display.getDefaultDisplaySync()
    //分辨率
    this.displayWidth = defaultDisplay.width
    this.displayHeight = defaultDisplay.height
    //刷新率
    this.displayRefreshRate = defaultDisplay.refreshRate
    //像素密度
    this.displayDensityDPI = defaultDisplay.densityDPI
  }

  //获取传感器信息
  async getSensorInfo() {
    //获取设备上的所有传感器信息
    // const list = sensor.getSensorListSync()
    const sensorList = await sensor.getSensorList()
    //通过map提取出传感器的id集合
    this.supportSensorIds = sensorList.map(item => item.sensorId)
    AlertDialog.show({
      message: this.supportSensorIds + ''
    })
  }

  @Builder
  ListTitle(title: string) {
    Text(title)
      .fontSize(16)
      .fontWeight(500)
      .fontColor($r('app.color.font'))
      .width('100%')
      .padding({
        left: 20,
        right: 20,
        top: 20,
        bottom: 10
      })
      .backgroundColor($r('app.color.white'))
  }

  build() {
    Navigation() {
      // 顶部硬件信息
      Column({ space: 20 }) {
        Text(this.marketName)
          .fontSize(16)
          .fontColor($r('app.color.white'))
        Column({ space: 10 }) {
          Text('系统版本：' + this.osFullName)
            .fontSize(12)
            .fontColor($r('app.color.white'))
          Text('API 版本：' + this.sdkApiVersion)
            .fontSize(12)
            .fontColor($r('app.color.white'))
          Text('设备类型：' + this.deviceType)
            .fontSize(12)
            .fontColor($r('app.color.white'))
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({
        left: 20,
        right: 20,
        top: 30,
        bottom: 30
      })
      .alignItems(HorizontalAlign.Start)

      // 其他内容
      Column() {
        List() {
          ListItemGroup({ header: this.ListTitle('基本信息') }) {
            // ListRow({ title: '上次启动', value: dayjs().subtract(this.uptime, 'second').format('YYYY-MM-DD HH:mm:ss') })
            // ListRow({ title: '运行时间', value: dayjs.duration(this.uptime, 'second').format('D天H小时mm分 ') })
            ListRow({ title: '上次启动', value: formatToDateTime(this.uptime) })
            ListRow({ title: '运行时间', value: formatToDate(this.uptime) })

          }

          ListItemGroup({ header: this.ListTitle('网络信息') }) {
            ListRow({ title: '网络类型', value: this.netBearType })
            ListRow({ title: 'IP地址', value: this.IPAddress })
            ListRow({ title: '子网掩码', value: this.subnetMask })
            ListRow({ title: '广播地址', value: this.broadcastAddress })
          }

          ListItemGroup({ header: this.ListTitle('硬件特性') }) {
            // 屏幕信息
            ListRow({ title: '屏幕分辨率（像素）', value: `${this.displayHeight}x${this.displayWidth}` })
            ListRow({ title: '屏幕刷新率（Hz）', value: this.displayRefreshRate })
            ListRow({ title: '像素密度（PPI）', value: this.displayDensityDPI })
            // 传感器信息
            ForEach(SENSOR_NAME_LIST, (item: SensorName) => {
              ListRow({
                title: item.sensorName,
                value: this.supportSensorIds.includes(item.sensorId) ? '有' : '-'
              })
            })
          }
        }
        .divider({ strokeWidth: 10 })
        .sticky(StickyStyle.Header)
        .height('100%')
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.white'))
      .borderRadius({ topLeft: 12, topRight: 12 })
      .clip(true)
    }
    .title(NavigationTitleBuilder('硬件信息'))
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .hideBackButton(true)
    .linearGradient({
      angle: 180,
      colors: [[$r('app.color.brand'), 0], [$r('app.color.brand_light'), 0.4], [$r('app.color.white'), 0.4]]
    })
  }
}

@Component
struct ListRow {
  @Prop title: string = ''
  @Prop value: string | number = ''

  build() {
    Row() {
      Text(this.title)
        .fontSize(14)
        .fontColor($r('app.color.font'))
      Text(this.value.toString())
        .fontSize(12)
        .fontColor($r('app.color.font_sub'))
    }
    .padding({ left: 20, right: 20 })
    .height(40)
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
  }
}

