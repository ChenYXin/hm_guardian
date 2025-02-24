import { PRIVACY_SETTINGS, PrivacySettings } from '../../../common/constants'
import { promptAction, router } from '@kit.ArkUI'

interface RouterParams {
  isForgetPassword?: boolean
}

@Entry
@Component
struct AuthPatternLockSettingsPage {
  // 获取隐私空间设置
  @StorageLink(PRIVACY_SETTINGS) privacySettings: PrivacySettings = {}
  // 正在输入的图形密码
  @State inputPassword: number[] = []
  // 第一次输入的密码
  @State firstPassword: number[] = []
  // 错误提示语
  @State errorMessage: string = ''
  // 路由参数
  @State routerParams: RouterParams = {}
  // 定时器，用于清空提示文案
  private timeoutID: number = -1
  // 控制器
  private patternLockController: PatternLockController = new PatternLockController()

  //输入完成后触发
  onPatternComplete(input: number[]) {
    //临时密码值
    this.inputPassword = input
    // TODO：密码输入结束时触发该回调
    if (input.length < 4) {
      this.errorMessage = '手势密码长度不能小于4位，请重新输入'
      this.patternLockController.setChallengeResult(PatternLockChallengeResult.WRONG)
    } else {
      this.errorMessage = ''
      this.patternLockController.setChallengeResult(PatternLockChallengeResult.CORRECT)

      //保存首次输入的密码
      if (this.firstPassword.length === 0) {
        this.firstPassword = input
      } else {
        //对比首次输入的密码还当前您的input
        if (this.firstPassword.toString() === input.toString()) {
          promptAction.showToast({ message: '密码设置成功' })
          //保存当前设置密码
          this.privacySettings.patternPassword = input.toString()
          //页面跳转
          router.pushUrl({ url: 'pages/Privacy/PrivacyIndexPage' })
        } else {
          this.errorMessage = '两次的密码不同'
          this.patternLockController.setChallengeResult(PatternLockChallengeResult.WRONG)
        }
      }
    }

    this.timeoutID = setTimeout(() => {
      this.patternLockController.reset()
      this.inputPassword = []
    }, 500)

  }

  build() {
    Navigation() {
      Column() {
        Text('当前临时输入的密码：' + this.inputPassword)
        Text('首次输入的密码¬：' + this.firstPassword)
        Text('持久化存储的密码：' + this.privacySettings.patternPassword)
      }

      Column({ space: 20 }) {
        Column({ space: 10 }) {
          // 请输入密码
          Text(this.firstPassword.length === 0 ? '设置手势密码' : '再次确认手势密码')
            .fontSize(16)
            .fontColor($r('app.color.font'))
          if (this.errorMessage) {
            Text(this.errorMessage)
              .fontSize(12)
              .fontColor($r('app.color.danger'))
          } else {
            Text(this.firstPassword.length === 0 ? '请绘制手势密码，至少链接4个点' : '请再次输入确认手势密码')
              .fontSize(12)
              .fontColor($r('app.color.font_sub'))
          }
        }

        PatternLock(this.patternLockController)
          .sideLength(320)// 宽高
          .circleRadius(12)// 圆点半径
          .pathStrokeWidth(10)// 线宽度
          .regularColor('#d9d9d9')// 未选中圆点色
          .activeColor('#800a59f7')// 经过圆点色
          .selectedColor(this.errorMessage && this.inputPassword.length !== 0 ? '#ffff5e5d' : '#ff0a59f7')// 选中圆点色
          .pathColor(this.errorMessage && this.inputPassword.length !== 0 ? '#ccff5e5d' : '#cc0a59f7')// 线颜色
          .onDotConnect(() => {
            // 密码输入选中宫格圆点时触发该回调
            clearTimeout(this.timeoutID)
          })
          .onPatternComplete((input: number[]) => {
            this.onPatternComplete(input)
          })
      }
      .padding({ top: 140 })
    }
    .title('隐私空间')
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
  }
}