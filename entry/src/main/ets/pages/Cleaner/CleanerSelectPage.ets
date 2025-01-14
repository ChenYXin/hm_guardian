import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { NavigationTitleBuilder } from '../../common/builders'
import { formatByteLength } from '../../common/utils'
import { themeManager, cleanerManager } from '../../manager'
import { promptAction, router } from '@kit.ArkUI'

interface RouterParams {
  name: string
}

@Entry
@Component
struct CleanerSelectPage {
  @State routerParams: RouterParams | null = null
  @State list: photoAccessHelper.PhotoAsset[] = []
  @State @Watch('onSelectedUrisChange') selectedUris: string[] = []
  @State selectedSize: number = 0

  aboutToAppear(): void {
    const params = router.getParams() as RouterParams
    if (params) {
      this.routerParams = params
      this.getList()
    }
  }

  onPageShow() {
    themeManager.settingStatusBarWhite()
  }

  onPageHide() {
    themeManager.settingStatusBarBlack()
  }

  async getList() {
    if (this.routerParams?.name === '屏幕截图') {
      this.list = await cleanerManager.getScreenshotList()
    }
  }

  async deletePhotos() {
    await cleanerManager.deletePhotos(this.selectedUris)
    promptAction.showToast({ message: '删除成功，共节省' + formatByteLength(this.selectedSize) })
    this.getList()
  }

  //当选择按钮发生变化时，计算节省空间大小
  onSelectedUrisChange() {
    const selectedList = this.list.filter(item => this.selectedUris.includes(item.uri))
    this.selectedSize = selectedList.reduce((acc, v) => v.get(photoAccessHelper.PhotoKeys.SIZE) as number + acc, 0)
  }

  build() {
    Navigation() {
      Column() {
        Column({ space: 10 }) {
          Text() {
            Span('可节省')
            Span(formatByteLength(this.selectedSize))
          }
          .fontSize(16)
          .fontColor($r('app.color.white'))

          Text(`已选择${this.selectedUris.length}张`)
            .fontSize(12)
            .fontColor($r('app.color.white'))
        }
        .justifyContent(FlexAlign.Center)
        .height(66)

        Scroll() {
          Column() {
            GridRow({ columns: 4, gutter: 8 }) {
              ForEach(this.list, (asset: photoAccessHelper.PhotoAsset) => {
                GridCol() {
                  Stack({ alignContent: Alignment.TopStart }) {
                    if (asset.photoType === photoAccessHelper.PhotoType.IMAGE) {
                      // 图片
                      Image(asset.uri)
                        .width('100%')
                        .aspectRatio(1)
                        .borderRadius(6)
                    } else if (asset.photoType === photoAccessHelper.PhotoType.VIDEO) {
                      // 视频
                      Video({ src: asset.uri })
                        .width('100%')
                        .aspectRatio(1)
                        .borderRadius(6)
                        .autoPlay(true)
                        .muted(true)
                        .controls(false)
                    }
                    Checkbox({ name: asset.uri })
                  }
                  .width('100%')
                  .aspectRatio(1)
                }

                //JSON.stringify(PhotoAsset)会得到{}空对象，最终导致ForEach通过唯一标识更新列表
              }, (item: photoAccessHelper.PhotoAsset) => item.uri)
            }

            Blank()
              .layoutWeight(1)
          }
          .padding(15)
        }
        .height('100%')
        .backgroundColor($r('app.color.white'))
      }
      .width('100%')
      .layoutWeight(1)

      Row({ space: 10 }) {
        Column() {
          CheckboxGroup()
            .onChange((event) => {
              this.selectedUris = event.name
            })
          Text('全选')
            .fontColor($r('app.color.font2'))
            .fontSize(12)
        }

        Button('删除')
          .type(ButtonType.Normal)
          .borderRadius(10)
          .layoutWeight(1)
          .height(42)
          .backgroundColor($r('app.color.danger'))
          .onClick(() => {
            //删除选中图片
            this.deletePhotos()
          })
      }
      .border({ width: { top: 1 }, color: $r('app.color.border') })
      .width('100%')
      .height(76)
      .padding({ left: 20, right: 20 })
      .backgroundColor($r('app.color.white'))
    }
    .title(NavigationTitleBuilder(this.routerParams?.name))
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .hideBackButton(true)
    .linearGradient({
      angle: 180,
      colors: [[$r('app.color.brand'), 0], [$r('app.color.brand_light'), 0.3], [$r('app.color.white'), 0.3]]
    })
  }
}