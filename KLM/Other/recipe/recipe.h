// updated 20220624

#ifndef RECIPE_H
#define RECIPE_H

typedef enum {
    IMAGE_FORMAT_RGBA = 0,   //RGBA RGBA
    IMAGE_FORMAT_RGB = 1,    //RGB RGB
    IMAGE_FORMAT_YUV420 = 2, //YYYYYYYY UU VV
    IMAGE_FORMAT_NV21 = 3,   //YYYYYYYY UVUV
}IMAGE_FORMAT;
typedef enum{
    Groceries = 1,
    Clothing,
    Plants,
    Others,
    Grocery_Fruits = 5,
    Grocery_Vegetable,
    Grocery_Iced,
    Grocery_Meat,
    Grocery_Bread,
}COMMODITY_CATEGORY;

/* 函数参数：
 * imgData:图像数据
 * imgW/imgH:图像宽高
 * format:图像格式，请按本头文件枚举类型IMAGE_FORMAT进行定义，定义错误将会引起内存泄漏
 * clickX/clickY:屏幕点击在图像中的位置（以像素为单位），请务必注意图像方向与imgData及imgW/imgH定义的保持一致!!!!!!!!
 * category:当前商品类别，请按本头文件枚举类型COMMODITY_CATEGORY进行定义
 * 函数返回值：
 * int型，当前画面推荐的配方索引值，向蓝牙发送此索引值即可控灯
 */
int getRecipeIndexOfImageOnClick(void * imgData, int imgW, int imgH, IMAGE_FORMAT format, int clickX, int clickY, COMMODITY_CATEGORY category);

/* 函数参数：
 * imgData:图像数据，IOS请用RGBA/RGB；Android请分辨图像的数据流格式为YUV420/NV21，并将其拼接成一个长度为H*W*1.5的数组
 * imgW/imgH:图像宽高
 * format:图像格式，请按本头文件枚举类型IMAGE_FORMAT进行定义，定义错误将会引起内存泄漏
 * startX/startY/endX/endY:框选的图像区域的起止点坐标（以像素为单位），请务必注意图像方向与imgData及imgW/imgH定义的保持一致!!!!!!!
 * category:当前商品类别，请按本头文件枚举类型COMMODITY_CATEGORY进行定义
 * 函数返回值：
 * int型，当前画面推荐的配方索引值，向蓝牙发送此索引值即可控灯
 */
int getRecipeIndexOfImageOnBox(void * imgData, int imgW, int imgH, IMAGE_FORMAT format, int startX, int startY, int endX, int endY, COMMODITY_CATEGORY category);

#endif
