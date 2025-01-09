import { permissionManager, themeManager } from '../../manager'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { picker } from '@kit.CoreFileKit'
import { dataSharePredicates } from '@kit.ArkData'
import { formatByteLength } from '../../common/utils'
import dayjs from 'dayjs'
import { promptAction } from '@kit.ArkUI'

@Entry
@Component
struct MediaLibraryKitTestPage {
  //媒体文件（图库）是否授权
  @State isAuth: boolean = false
  //图片数量
  @State photoCount: number = 0
  //图片的路径
  @State photoAssetUri: string = ''
  //图片的名称
  @State photoAssetDisplayName: string = ''
  //图片的文件大小
  @State photoAssetSize: number = 0
  //添加日期（添加文件时间距1970年1月1日的秒数值）
  @State photoAssetDateAdded: string = ''
  //相册
  @State albumCount: string = ''
  @State albumName: string = ''
  @State albumCoverUri: string = ''

  aboutToAppear(): void {
    this.requestPermissions()
  }

  async requestPermissions() {
    this.isAuth = await permissionManager.requestPermissions([
      'ohos.permission.READ_IMAGEVIDEO',
      'ohos.permission.WRITE_IMAGEVIDEO'
    ])
  }

  build() {
    Navigation() {
      Scroll() {
        Column({ space: 10 }) {
          Text('图库读写是否授权 - isAuth : ' + this.isAuth)

          Button('使用Picker选择媒体库资源 - 无需申请权限')
            .onClick(() => {
              let uris: Array<string> = [];
              //图库 Picker
              // const photoViewPicker1 = new picker.PhotoViewPicker(); // 已过时
              const photoViewPicker = new photoAccessHelper.PhotoViewPicker(); //应用内打开图库，无需跳转图库应用
              photoViewPicker.select()
                .then((photoSelectResult) => {
                  uris = photoSelectResult.photoUris;
                  AlertDialog.show({
                    message: JSON.stringify(photoSelectResult, null, 2)
                  })
                })

            })
          //需要获取权限
          Button('获取图库资源')
            .onClick(async () => {
              //1.获取图库管理器
              const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(getContext())
              //2.谓词 predicate 是一个类型 需要new 创建实例
              const predicates = new dataSharePredicates.DataSharePredicates()
              // predicates.orderByAsc() //正序：从小到大
              predicates.orderByDesc(photoAccessHelper.PhotoKeys.DATE_ADDED) //倒序：从大到小

              // 获取图库资源核心API getAssets
              const fetchResult = await phAccessHelper.getAssets({
                //比传参数：查询列
                fetchColumns: [photoAccessHelper.PhotoKeys.SIZE, photoAccessHelper.PhotoKeys.DATE_ADDED],
                //比传参数：谓词（查询条件）
                predicates: predicates
              })
              this.photoCount = fetchResult.getCount()
              //获取第一张图片资源
              const photoAsset = await fetchResult.getFirstObject()
              //图片的路径
              this.photoAssetUri = photoAsset.uri
              //图片的名称
              this.photoAssetDisplayName = photoAsset.displayName
              //获取图片的文件大小
              //注意事项：若忘记在 fetchColumns 添加查询字段，get 获取时会报错，比较容易踩坑
              this.photoAssetSize = photoAsset.get(photoAccessHelper.PhotoKeys.SIZE) as number
              //添加日期（添加文件时间距1970年1月1日的秒数值）
              //注意事项：ArkTS 中时间戳是毫秒值，秒数值 需要乘 1000 后再用于 dayjs进行格式化
              const dateAdded = photoAsset.get(photoAccessHelper.PhotoKeys.DATE_ADDED) as number
              this.photoAssetDateAdded = dayjs(dateAdded * 1000)
                .format('YYYY-MM-DD HH:mm:ss')
            })
          Text('图片数量：' + this.photoCount)
          Text('图片路径：' + this.photoAssetUri)
          Text('图片名称：' + this.photoAssetDisplayName)
          Text('图片文件的大小：' + formatByteLength(this.photoAssetSize))
          Text('图片文件的添加日期：' + this.photoAssetDateAdded)
          Image(this.photoAssetUri)
            .width(200)
            .autoResize(true)

          Button('删除图片')
            .onClick(async () => {
              //1.获取图库管理器
              const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(getContext())
              //2.谓词 predicate 是一个类型 需要new 创建实例
              const predicates = new dataSharePredicates.DataSharePredicates()

              // 获取图库资源核心API getAssets
              const fetchResult = await phAccessHelper.getAssets({
                //比传参数：查询列
                fetchColumns: [],
                //比传参数：谓词（查询条件）
                // predicates: predicates
                predicates
              })
              //3.调用 fetchResult.getFirstObject 接口获取第一张图片，即要放入回收站的图片对象
              const photoAsset = await fetchResult.getFirstObject()
              //4.调用 MediaAssetChangeRequest 接口将文件放入回收站(删除)
              await photoAccessHelper.MediaAssetChangeRequest.deleteAssets(getContext(), [photoAsset])
              promptAction.showToast({ message: '删除成功' })
            })

          Button('获取用户相册')
            .onClick(async () => {
              //1.获取图库管理器
              const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(getContext())
              //2.谓词 predicate 是一个类型 需要new 创建实例
              const predicates = new dataSharePredicates.DataSharePredicates()
              //3. 调用 PhotoAccessHelper.getAlbums 接口获取用户相册资源
              const fetchResult = await phAccessHelper.getAlbums(
                photoAccessHelper.AlbumType.USER,
                photoAccessHelper.AlbumSubtype.USER_GENERIC,
                {
                  fetchColumns: [],
                  predicates
                }
              )
              //4. 调用 fetchResult.getFirstObject 接口获取第一个用户相册
              const album = await fetchResult.getFirstObject()
              this.albumCount = album.count.toString()
              this.albumName = album.albumName
              this.albumCoverUri = album.coverUri
            })
          Image(this.albumCoverUri)
            .width(100)
            .height(100)
          Text(`相册名称：${this.albumName}`)
          Text(`相册数量：${this.albumCount}`)
        }
      }
      .constraintSize({ minHeight: '100%' })
    }
    .title('Media Library Kit (媒体文件管理服务 - 图库)')
    .titleMode(NavigationTitleMode.Mini)
  }
}