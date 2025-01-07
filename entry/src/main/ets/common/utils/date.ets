//导入 dayjs 核心包
import dayjs from 'dayjs'
//导入 dayjs 插件（相对时间 - 运行时间）
import duration from 'dayjs/plugin/duration'

//注册 dayjs 插件（相对时间 - 运行时间）
dayjs.extend(duration)

export function formatToDateTime(seconds: number) {
  const dayjsInstance = dayjs().subtract(seconds, 'seconds')
  return dayjsInstance.format('YYYY-MM-DD HH:mm:ss')
}

export function formatToDate(seconds: number) {
  const dayjsInstance = dayjs.duration(seconds, 'second')
  return dayjsInstance.format('D天H小时mm分')
}