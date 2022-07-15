//
// Created by gxy on 2021/7/2.
//
#include <stdlib.h>
#include "recipe.h"
#include <math.h>
#define min3v(v1, v2, v3)   ((v1)>(v2)? ((v2)>(v3)?(v3):(v2)):((v1)>(v3)?(v3):(v1)))
#define max3v(v1, v2, v3)   ((v1)<(v2)? ((v2)<(v3)?(v3):(v2)):((v1)<(v3)?(v3):(v1)))


//#include <android/log.h>
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, "CameraView", __VA_ARGS__);

typedef enum {
    SPECTRUM_ROSEWOOD            = 0,   //0
    SPECTRUM_CHAMPAGNE              ,   //1
    SPECTRUM_COFFEE                 ,   //2
    SPECTRUM_WARM_WHITE             ,   //3
    SPECTRUM_RED                    ,   //4
    SPECTRUM_RED_ORANGE             ,
    SPECTRUM_ORANGE                 ,   //5
    SPECTRUM_ORANGE_YELLOW          ,
    SPECTRUM_YELLOW                 ,   //6
    SPECTRUM_YELLOW_GREEN           ,   //7
    SPECTRUM_GREEN                  ,   //8
    SPECTRUM_GREEN_CYAN             ,   //9
    SPECTRUM_CYAN                   ,  //10
    SPECTRUM_CYAN_BLUE              ,
    SPECTRUM_BLUE                   ,  //11
    SPECTRUM_BLUE_PURPLE            ,
    SPECTRUM_PURPLE                 ,  //12
    SPECTRUM_PINK	                ,  //13
    SPECTRUM_LIGHT_RED              ,  //14
    SPECTRUM_LIGHT_RED_ORANGE       ,
    SPECTRUM_LIGHT_ORANGE           ,  //15
    SPECTRUM_LIGHT_ORANGE_YELLOW    ,
    SPECTRUM_LIGHT_YELLOW           ,  //16
    SPECTRUM_LIGHT_YELLOW_GREEN     ,  //17
    SPECTRUM_LIGHT_GREEN            ,  //18
    SPECTRUM_LIGHT_GREEN_CYAN       ,  //19
    SPECTRUM_LIGHT_CYAN             ,  //20
    SPECTRUM_LIGHT_CYAN_BLUE        ,
    SPECTRUM_LIGHT_BLUE             ,  //21
    SPECTRUM_LIGHT_BLUE_PURPLE      ,
    SPECTRUM_LIGHT_PURPLE           ,  //22
    SPECTRUM_LIGHT_PINK	            ,  //23
    SPECTRUM_BLACK                  ,  //24
    SPECTRUM_WHITE                  ,  //25
    SPECTRUM_3000K                  ,  //26
    SPECTRUM_3500K                  ,  //27
    SPECTRUM_4000K                  ,  //28
    SPECTRUM_FULL                   ,  //29
    SPECTRUM_3800K                  ,
    SPECTRUM_UNDEFINED,
}Spectrum_Index;
typedef enum {
    COLOR_ROSEWOOD                  ,   //0
    COLOR_CHAMPAGNE                 ,   //1
    COLOR_COFFEE                    ,   //2
    COLOR_WARM_WHITE                ,   //3
    COLOR_RED                       ,   //
    COLOR_RED_ORANGE                ,
    COLOR_ORANGE                    ,   //5
    COLOR_ORANGE_YELLOW             ,
    COLOR_YELLOW                    ,   //6
    COLOR_YELLOW_GREEN              ,   //7
    COLOR_GREEN                     ,   //8
    COLOR_GREEN_CYAN                ,   //9
    COLOR_CYAN                      ,  //10
    COLOR_CYAN_BLUE                 ,
    COLOR_BLUE                      ,  //11
    COLOR_BLUE_PURPLE               ,
    COLOR_PURPLE                    ,  //12
    COLOR_PINK	                    ,  //13
    COLOR_LIGHT_RED                 ,  //14
    COLOR_LIGHT_RED_ORANGE          ,
    COLOR_LIGHT_ORANGE              ,  //15
    COLOR_LIGHT_ORANGE_YELLOW       ,
    COLOR_LIGHT_YELLOW              ,  //16
    COLOR_LIGHT_YELLOW_GREEN        ,  //17
    COLOR_LIGHT_GREEN               ,  //18
    COLOR_LIGHT_GREEN_CYAN          ,  //19
    COLOR_LIGHT_CYAN                ,  //20
    COLOR_LIGHT_CYAN_BLUE           ,
    COLOR_LIGHT_BLUE                ,  //21
    COLOR_LIGHT_BLUE_PURPLE         ,
    COLOR_LIGHT_PURPLE              ,  //22
    COLOR_LIGHT_PINK	            ,  //23
    COLOR_BLACK                     ,  //24
    COLOR_WHITE                     ,  //25
    COLOR_UNDEFINED,
}Color_Index;
typedef enum{
    COLD_BLACK_WHITE = 0,
    COLD_CYAN_BLUE_PURPLE,
    WARM_RED,
    NEUTRAL_GREEN,
    WARM_ROSEWOOD,
    WARM_ORANGE_YELLOW,
} Color_Index_S;
typedef enum {
    SPECTRUM_GROCERY_WHITE,
    SPECTRUM_GROCERY_BLACK,
    SPECTRUM_GROCERY_RED,
    SPECTRUM_GROCERY_ORANGE,
    SPECTRUM_GROCERY_YELLOW,
    SPECTRUM_GROCERY_GREEN_CYAN,
    SPECTRUM_GROCERY_BLUE_PURPLE,
    SPECTRUM_GROCERY_3000K,
    SPECTRUM_GROCERY_3500K,
    SPECTRUM_GROCERY_4000K,
    SPECTRUM_GROCERY_DEFAULT,
}Spectrum_Index_Grocery;
typedef struct{
    unsigned char  R;
    unsigned char  G;
    unsigned char  B;
}COLOR_RGB;
typedef struct{
    short H;
    unsigned char S;
    unsigned char V;
}COLOR_HSV;
typedef struct {
    unsigned char Y;
    unsigned char U;
    unsigned char V;
}COLOR_YUV;
typedef struct{
    int X_Start;
    int X_End;
    int Y_Start;
    int Y_End;
}IMAGE_AREA;


void RGBtoHSV100(const COLOR_RGB *rgb, COLOR_HSV *hsv){
    int h, s, v, maxVal, minVal, difVal;
    int r = rgb->R;
    int g = rgb->G;
    int b = rgb->B;
    maxVal = max3v(r, g, b);
    minVal = min3v(r, g, b);
    difVal = maxVal - minVal;

    v = maxVal * 100.0 / 255;
    if (maxVal <= 0) {
        s = 0;
    } else {
        s = 100.0 * difVal / maxVal;
    }

    if(difVal == 0){
        h = 0;
    } else {
        if(maxVal == r){
            if(g >= b)
                h = 60*(g - b)/(difVal);
            else
                h = 60*(g - b)/(difVal) + 360;
        }
        else if(maxVal == g)
            h = 60 * (b - r)/(difVal) + 120;
        else if(maxVal == b)
            h = 60 * (r - g)/(difVal) + 240;
    }
    hsv->H = (short)(((h > 360) ? 360 : ((h < 0) ? 0: h)));
    hsv->S = (unsigned char)(((s > 100) ? 100 : ((s < 0) ? 0: s)));
    hsv->V = (unsigned char)(((v > 100) ? 100 : ((v < 0) ? 0: v)));
}
void YUVtoHSV100(const COLOR_YUV *yuv, COLOR_HSV *hsv){
    COLOR_RGB rgb;
    int r = yuv->Y + 1.37 * (yuv->V - 128);
    int g = yuv->Y - 0.70 * (yuv->V - 128) - 0.34 * (yuv->U - 128);
    int b = yuv->Y + 1.73 * (yuv->U - 128);
    rgb.R = (unsigned char)(((r > 255) ? 255 : ((r < 0) ? 0: r)));
    rgb.G = (unsigned char)(((g > 255) ? 255 : ((g < 0) ? 0: g)));
    rgb.B = (unsigned char)(((b > 255) ? 255 : ((b < 0) ? 0: b)));
    RGBtoHSV100(&rgb, hsv);
}
void YUVtoRGB(const COLOR_YUV *yuv, COLOR_RGB *rgb) {
    int r = yuv->Y + 1.37 * (yuv->V - 128);
    int g = yuv->Y - 0.70 * (yuv->V - 128) - 0.34 * (yuv->U - 128);
    int b = yuv->Y + 1.73 * (yuv->U - 128);
    rgb->R = (unsigned char)(((r > 255) ? 255 : ((r < 0) ? 0: r)));
    rgb->G = (unsigned char)(((g > 255) ? 255 : ((g < 0) ? 0: g)));
    rgb->B = (unsigned char)(((b > 255) ? 255 : ((b < 0) ? 0: b)));
}
void sort_array_and_indexes_int(int * array, int * indexes, int start, int end, int if_set_indexes) {
    int i, j, max_index = -1, swap_temp;
    if (if_set_indexes) {
        for (i = start; i <= end; i++) {
            indexes[i - start] = i;
        }
    }

    for (i = start; i <= end; i++) {
        max_index = i;
        for (j = i + 1; j <= end; j++) {
            if (array[j] - array[max_index] > 0) max_index = j;
        }
        if (max_index != i) {
            swap_temp = array[i];
            array[i] = array[max_index];
            array[max_index] = swap_temp;

            swap_temp = indexes[i - start];
            indexes[i - start] = indexes[max_index - start];
            indexes[max_index - start] = swap_temp;
        }
    }
}
Color_Index get_color_hsv(COLOR_HSV Hsv) {
    if (Hsv.H < 10 || Hsv.H >= 300) { // red
        if ((Hsv.H > 340 || Hsv.H < 10) && Hsv.S >= 40 && (Hsv.V > 15 && Hsv.V <= 40)) return COLOR_ROSEWOOD;
        if (Hsv.V <= 30) return COLOR_BLACK;
        if (Hsv.S <= 10) return COLOR_WHITE;
        if (Hsv.H >= 300 && Hsv.H < 343) {
            if (Hsv.S < 40 && Hsv.V > 70) return COLOR_LIGHT_PINK;
            return COLOR_PINK;
        }
        if (Hsv.S < 40 && Hsv.V > 70) return COLOR_LIGHT_RED;
        return COLOR_RED;
    } else if (Hsv.H >= 10 && Hsv.H < 58) { // orange
        if (Hsv.H < 41 && Hsv.V > 15 && Hsv.V <= 40) return COLOR_COFFEE;
        if (Hsv.V <= 30) return COLOR_BLACK;
        if (Hsv.S <= 10) return COLOR_WHITE;
        if (Hsv.S <= 25) return COLOR_WARM_WHITE;
        if (Hsv.H < 30) { // red orange
            if (Hsv.S < 40 && Hsv.V > 70) return COLOR_LIGHT_RED_ORANGE;
            return COLOR_RED_ORANGE;
        }
        if (Hsv.H >= 45) { // orange yellow
            if (Hsv.S < 40 && Hsv.H > 70) return COLOR_LIGHT_ORANGE_YELLOW;
            return COLOR_ORANGE_YELLOW;
        }
        if (Hsv.S < 40 && Hsv.V > 70) return  COLOR_LIGHT_ORANGE;
        if (Hsv.S <= 50 && Hsv.V >= 50) return COLOR_CHAMPAGNE;
        return COLOR_ORANGE;
    } else if (Hsv.V <= 30) return COLOR_BLACK;
    else if (Hsv.S <= 10) return COLOR_WHITE;
    else if (Hsv.H >= 58 && Hsv.H < 68) { // yellow
        if (Hsv.S < 40 && Hsv.H > 70) return COLOR_LIGHT_YELLOW;
        return COLOR_YELLOW;
    } else if (Hsv.H >= 68 && Hsv.H < 141) { //green
        if (Hsv.S < 40 && Hsv.V > 70) {
            if (Hsv.H < 89) return COLOR_LIGHT_YELLOW_GREEN;
            return COLOR_LIGHT_GREEN;
        } else {
            if (Hsv.H < 89) return COLOR_YELLOW_GREEN;
            return COLOR_GREEN;
        }
    } else if (Hsv.H >= 141 && Hsv.H < 211) { //cyan
        if (Hsv.S < 40 && Hsv.V > 70) {
            if (Hsv.H < 165) return COLOR_LIGHT_GREEN_CYAN;
            if (Hsv.H < 185) return COLOR_LIGHT_CYAN;
            return COLOR_LIGHT_CYAN_BLUE;
        } else {
            if (Hsv.H < 165) return COLOR_GREEN_CYAN;
            if (Hsv.H < 185) return COLOR_CYAN;
            return COLOR_CYAN_BLUE;
        }
    } else if (Hsv.H >= 211 && Hsv.H < 240) { //blue
        if (Hsv.S < 40 && Hsv.V > 70) return COLOR_LIGHT_BLUE;
        else return COLOR_BLUE;
    } else if (Hsv.H >= 240 && Hsv.H < 300) { //purple
        if (Hsv.S < 40 && Hsv.V > 70) {
            if (Hsv.H < 260) return COLOR_LIGHT_BLUE_PURPLE;
            return COLOR_LIGHT_PURPLE;
        }
        else {
            if (Hsv.H < 260) return COLOR_BLUE_PURPLE;
            return COLOR_PURPLE;
        }
    }
    return COLOR_WHITE;
}
Color_Index_S get_color_s_hsv(COLOR_HSV Hsv) {
    if ((Hsv.H > 340 || Hsv.H < 41) && (Hsv.S >= 40) && (Hsv.V > 15 && Hsv.V <= 40)) return WARM_ROSEWOOD;
    if (Hsv.V <= 30 || Hsv.S <= 10) return COLD_BLACK_WHITE;
    if ((Hsv.H >= 10 && Hsv.H < 58) && Hsv.S <= 25) return COLD_BLACK_WHITE;
    if (Hsv.H >= 141 && Hsv.H < 300) return COLD_CYAN_BLUE_PURPLE;
    if (Hsv.H >= 68 && Hsv.H < 141) return NEUTRAL_GREEN;
    if (Hsv.H >= 10 && Hsv.H < 68)  return WARM_ORANGE_YELLOW;
    if (Hsv.H < 10 || Hsv.H >= 300) return WARM_RED;
    return COLD_BLACK_WHITE;
}
Spectrum_Index getRecipeIndexOfImageROI(void * imgData, int imgW, int imgH, IMAGE_FORMAT format, const IMAGE_AREA * area) {
    int color_dict[6] = {0}, sorted_indexes_s[6] = {0, 1, 2, 3, 4, 5}, real_colors[6], sum = 0;
    float avg_rgb[6][3] = {0};  // use rgb not hsv
    unsigned char * p = (unsigned char *)imgData;
    COLOR_RGB rgb;
    COLOR_HSV hsv;
    COLOR_YUV yuv;
    for (int y = area->Y_Start; y < area->Y_End; y++) {
        for (int x = area->X_Start; x < area->X_End; x++) {
            if (format == IMAGE_FORMAT_RGBA) {
                rgb.R = p[(y * imgW + x) * 4 + 0];
                rgb.G = p[(y * imgW + x) * 4 + 1];
                rgb.B = p[(y * imgW + x) * 4 + 2];
                RGBtoHSV100(&rgb, &hsv);
            } else if (format == IMAGE_FORMAT_RGB) {
                rgb.R = p[(y * imgW + x) * 3 + 0];
                rgb.G = p[(y * imgW + x) * 3 + 1];
                rgb.B = p[(y * imgW + x) * 3 + 2];
                RGBtoHSV100(&rgb, &hsv);
            } else if (format == IMAGE_FORMAT_YUV420)  {
                yuv.Y = p[y * imgW + x];
                yuv.U = p[(int)(imgW * imgH + (y / 2) * (imgW / 2) + x / 2)];
                yuv.V = p[(int)(imgW * imgH * 3 / 2 + (y / 2) * (imgW / 2) + x / 2)];
                YUVtoRGB(&yuv, &rgb);
                YUVtoHSV100(&yuv, &hsv);
            } else if (format == IMAGE_FORMAT_NV21) {
                yuv.Y = p[y * imgW + x];
                yuv.U = p[(int)(imgW * imgH + (y / 2) * imgW + x - (x % 2))];
                yuv.V = p[(int)(imgW * imgH + (y / 2) * imgW + x - (x % 2) + 1)];
                YUVtoRGB(&yuv, &rgb);
                YUVtoHSV100(&yuv, &hsv);
            }
            sum++;
            int index = (int)get_color_s_hsv(hsv);
            avg_rgb[index][0] += rgb.R; //color
            avg_rgb[index][1] += rgb.G;
            avg_rgb[index][2] += rgb.B;
            color_dict[index]++; // at last
        }
    }
//    LOGI("sum %d", sum);
    for (int i = 0; i < 6; i++) {
        if (color_dict[i] < 0.05 * sum) {
            sum -= color_dict[i];
            color_dict[i] = 0;
            continue;
        }
        for (int j = 0; j < 3; j++)	{
            avg_rgb[i][j] /= color_dict[i];
        }
        rgb.R = (unsigned char)avg_rgb[i][0];
        rgb.G = (unsigned char)avg_rgb[i][1];
        rgb.B = (unsigned char)avg_rgb[i][2];
        RGBtoHSV100(&rgb, &hsv);
        real_colors[i] = get_color_hsv(hsv);
//        LOGI("%d real color %d, pixel num %d", i, real_colors[i], color_dict[i]);
    }
    int ncw = color_dict[COLD_BLACK_WHITE] + color_dict[COLD_CYAN_BLUE_PURPLE]; // this should be before sort!! very important!
    int nnw = color_dict[NEUTRAL_GREEN];
    int nww = color_dict[WARM_ROSEWOOD] + color_dict[WARM_ORANGE_YELLOW] + color_dict[WARM_RED];

    sort_array_and_indexes_int(color_dict, sorted_indexes_s, 0, 5, 0);
    if (color_dict[0] > sum * 0.7) { // pure color
        if (sorted_indexes_s[0] == COLD_BLACK_WHITE) {
            if (real_colors[sorted_indexes_s[0]] == COLOR_WARM_WHITE) return SPECTRUM_WARM_WHITE;
            else return SPECTRUM_WHITE;
        }
        return (Spectrum_Index)real_colors[sorted_indexes_s[0]];
    }
    if (color_dict[0] + color_dict[1] > 0.9 * sum) {
        if (real_colors[sorted_indexes_s[1]] == COLD_BLACK_WHITE) return (Spectrum_Index)real_colors[sorted_indexes_s[0]];
    }

    if (ncw > sum * 0.6) return SPECTRUM_4000K;
    if (nnw > sum * 0.6) return SPECTRUM_3500K;
    if (nww > sum * 0.6) return SPECTRUM_3000K;
    if (ncw + nnw > 0.8) return SPECTRUM_3800K;
    if (ncw + nww > 0.8) return SPECTRUM_3500K;
    return SPECTRUM_FULL;
}
Spectrum_Index_Grocery get_spectrum_index_of_grocery_image(void * imgData, int imgW, int imgH, IMAGE_FORMAT format, const IMAGE_AREA * area, int category) {
    if (category == Grocery_Bread) return SPECTRUM_GROCERY_DEFAULT;
    int color_dict[7] = {0}, sum = 0;
    unsigned char * p = (unsigned char *)imgData;
    COLOR_RGB rgb;
    COLOR_HSV hsv;
    COLOR_YUV yuv;
    for (int y = area->Y_Start; y <= area->Y_End; y++) {
        for (int x = area->X_Start; x <= area->X_End; x++) {
            if (format == IMAGE_FORMAT_RGBA) {
                rgb.R = p[(y * imgW + x) * 4 + 0];
                rgb.G = p[(y * imgW + x) * 4 + 1];
                rgb.B = p[(y * imgW + x) * 4 + 2];
                RGBtoHSV100(&rgb, &hsv);
            } else if (format == IMAGE_FORMAT_RGB) {
                rgb.R = p[(y * imgW + x) * 3 + 0];
                rgb.G = p[(y * imgW + x) * 3 + 1];
                rgb.B = p[(y * imgW + x) * 3 + 2];
                RGBtoHSV100(&rgb, &hsv);
            } else if (format == IMAGE_FORMAT_YUV420)  {
                yuv.Y = p[y * imgW + x];
                yuv.U = p[(int)(imgW * imgH + (y / 2) * (imgW / 2) + x / 2)];
                yuv.V = p[(int)(imgW * imgH * 3 / 2 + (y / 2) * (imgW / 2) + x / 2)];
                YUVtoRGB(&yuv, &rgb);
                YUVtoHSV100(&yuv, &hsv);
            } else if (format == IMAGE_FORMAT_NV21) {
                yuv.Y = p[y * imgW + x];
                yuv.U = p[(int)(imgW * imgH + (y / 2) * imgW + x - (x % 2))];
                yuv.V = p[(int)(imgW * imgH + (y / 2) * imgW + x - (x % 2) + 1)];
                YUVtoRGB(&yuv, &rgb);
                YUVtoHSV100(&yuv, &hsv);
            }
            sum++;
            if (hsv.S <= 30 && hsv.V >= 40) color_dict[SPECTRUM_GROCERY_WHITE]++;
            else if (hsv.V <= 40) color_dict[SPECTRUM_GROCERY_BLACK]++;
            else if (hsv.H < 288 && hsv.H >= 211) color_dict[SPECTRUM_GROCERY_BLUE_PURPLE]++;
            else if (hsv.H < 211 && hsv.H >= 89) color_dict[SPECTRUM_GROCERY_GREEN_CYAN]++;
            else if (hsv.H < 89 && hsv.H >= 45) color_dict[SPECTRUM_GROCERY_YELLOW]++;
            else if (hsv.H < 45 && hsv.H >= 20) color_dict[SPECTRUM_GROCERY_ORANGE]++;
            else color_dict[SPECTRUM_GROCERY_RED]++;
        }
    }
    int nww = color_dict[SPECTRUM_GROCERY_RED] + color_dict[SPECTRUM_GROCERY_YELLOW] + color_dict[SPECTRUM_GROCERY_ORANGE];
    int ncw = color_dict[SPECTRUM_GROCERY_BLUE_PURPLE] + color_dict[SPECTRUM_GROCERY_GREEN_CYAN];
    int nnw = color_dict[SPECTRUM_GROCERY_WHITE] + color_dict[SPECTRUM_GROCERY_BLACK];
    if (category == Grocery_Meat) {
        if (nww > 0.65 * sum) return SPECTRUM_GROCERY_RED;
        else if (nnw > 0.65 * sum) return SPECTRUM_GROCERY_WHITE;
    } else {
        for (int i = 0; i < 7; i++) {
            if (color_dict[i] > 0.65 * sum) return i;
        }
    }
    if (nww > 0.5 * sum) return SPECTRUM_GROCERY_3000K;
    if (ncw > 0.5 * sum) return SPECTRUM_GROCERY_4000K;
    if (nnw > 0.5 * sum) return SPECTRUM_GROCERY_3500K;
    return SPECTRUM_GROCERY_DEFAULT;
}
int getRecipeIndexOfImageOnClick(void * imgData, int imgW, int imgH, IMAGE_FORMAT format, int clickX, int clickY, COMMODITY_CATEGORY category) {
    int radius = 5;
    int startX = clickX - radius < 0 ? 0: clickX - radius;
    int endX = clickX + radius >= imgW ? imgW - 1: clickX + radius;
    int startY = clickY - radius < 0 ? 0: clickY - radius;
    int endY = clickY + radius >= imgH ? imgH - 1: clickY + radius;

    IMAGE_AREA area = {startX, endX, startY, endY};
//    LOGI("%d, %d, %d, %d", startX, endX , startY, endY);
    if (category >= Grocery_Fruits) return get_spectrum_index_of_grocery_image(imgData, imgW, imgH, format, &area, category);
    else return getRecipeIndexOfImageROI(imgData, imgW, imgH, format, &area);
}
int getRecipeIndexOfImageOnBox(void * imgData, int imgW, int imgH, IMAGE_FORMAT format, int startX, int startY, int endX, int endY, COMMODITY_CATEGORY category){
    IMAGE_AREA area = {startX, endX, startY, endY};
    if (category >= Grocery_Fruits) return get_spectrum_index_of_grocery_image(imgData, imgW, imgH, format, &area, category);
    else return getRecipeIndexOfImageROI(imgData, imgW, imgH, format, &area);
}
