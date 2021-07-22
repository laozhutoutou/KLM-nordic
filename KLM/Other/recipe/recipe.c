//
// Created by gxy on 2021/7/2.
//
#include <stdlib.h>
#include "recipe.h"
#define min3v(v1, v2, v3)   ((v1)>(v2)? ((v2)>(v3)?(v3):(v2)):((v1)>(v3)?(v3):(v1)))
#define max3v(v1, v2, v3)   ((v1)<(v2)? ((v2)<(v3)?(v3):(v2)):((v1)<(v3)?(v3):(v1)))

typedef enum {
    SPECTRUM_ROSEWOOD           = 0,   //0
    SPECTRUM_CHAMPAGNE          = 1,   //1
    SPECTRUM_COFFEE             = 2,   //2
    SPECTRUM_WARM_WHITE         = 3,   //3
    SPECTRUM_RED                = 4,   //4
    SPECTRUM_ORANGE             = 5,   //5
    SPECTRUM_YELLOW             = 6,   //6
    SPECTRUM_YELLOW_GREEN       = 7,   //7
    SPECTRUM_GREEN              = 8,   //8
    SPECTRUM_GREEN_CYAN         = 9,   //9
    SPECTRUM_CYAN               = 10,  //10
    SPECTRUM_BLUE               = 11,  //11
    SPECTRUM_PURPLE             = 12,  //12
    SPECTRUM_PINK	              = 13,  //13
    SPECTRUM_LIGHT_RED          = 14,  //14
    SPECTRUM_LIGHT_ORANGE       = 15,  //15
    SPECTRUM_LIGHT_YELLOW       = 16,  //16
    SPECTRUM_LIGHT_YELLOW_GREEN = 17,  //17
    SPECTRUM_LIGHT_GREEN        = 18,  //18
    SPECTRUM_LIGHT_GREEN_CYAN   = 19,  //19
    SPECTRUM_LIGHT_CYAN         = 20,  //20
    SPECTRUM_LIGHT_BLUE         = 21,  //21
    SPECTRUM_LIGHT_PURPLE       = 22,  //22
    SPECTRUM_LIGHT_PINK	        = 23,  //23
    SPECTRUM_BLACK              = 24,  //24
    SPECTRUM_WHITE              = 25,  //25
    SPECTRUM_3000K              = 26,  //26
    SPECTRUM_3500K              = 27,  //27
    SPECTRUM_4000K              = 28,  //28
    SPECTRUM_FULL               = 29,  //29
    SPECTRUM_UNDEFINED,
}Spectrum_Index;
typedef enum {
    COLOR_ROSEWOOD              ,   //0
    COLOR_CHAMPAGNE             ,   //1
    COLOR_COFFEE                ,   //2
    COLOR_WARM_WHITE            ,   //3
    COLOR_RED                   ,   //4
    COLOR_ORANGE                ,   //5
    COLOR_YELLOW                ,   //6
    COLOR_YELLOW_GREEN          ,   //7
    COLOR_GREEN                 ,   //8
    COLOR_GREEN_CYAN            ,   //9
    COLOR_CYAN                  ,  //10
    COLOR_BLUE                  ,  //11
    COLOR_PURPLE                ,  //12
    COLOR_PINK	                ,  //13
    COLOR_LIGHT_RED             ,  //14
    COLOR_LIGHT_ORANGE          ,  //15
    COLOR_LIGHT_YELLOW          ,  //16
    COLOR_LIGHT_YELLOW_GREEN    ,  //17
    COLOR_LIGHT_GREEN           ,  //18
    COLOR_LIGHT_GREEN_CYAN      ,  //19
    COLOR_LIGHT_CYAN            ,  //20
    COLOR_LIGHT_BLUE            ,  //21
    COLOR_LIGHT_PURPLE          ,  //22
    COLOR_LIGHT_PINK	          ,  //23
    COLOR_BLACK                 ,  //24
    COLOR_WHITE                 ,  //25
    COLOR_UNDEFINED,
}Color_Index;
typedef enum {
    COLOR_BLACK_S,
    COLOR_WHITE_S,
    COLOR_RED_S,
    COLOR_ORANGE_S,
    COLOR_YELLOW_S,
    COLOR_GREEN_S,
    COLOR_CYAN_S,
    COLOR_BLUE_S,
    COLOR_PURPLE_S,
    COLOR_UNDEFINED_S,
}Color_Index_Simplified;
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


int if_color_warm(Color_Index color) {
    if (color == COLOR_ROSEWOOD || color == COLOR_CHAMPAGNE || color == COLOR_COFFEE ||
        color == COLOR_RED || color == COLOR_ORANGE|| color == COLOR_YELLOW|| color == COLOR_PINK ||
        color == COLOR_LIGHT_RED || color == COLOR_LIGHT_ORANGE|| color == COLOR_LIGHT_YELLOW|| color == COLOR_LIGHT_PINK) return 1;
    return 0;
}
int if_color_neutral(Color_Index color) {
    if (color == COLOR_WARM_WHITE || color == COLOR_YELLOW_GREEN || color == COLOR_GREEN || color == COLOR_PURPLE || color == COLOR_BLACK ||
        color == COLOR_LIGHT_YELLOW_GREEN|| color == COLOR_LIGHT_GREEN|| color == COLOR_LIGHT_PURPLE || color == COLOR_WHITE) return 1;
    return 0;
}
int if_color_cold(Color_Index color) {
    if (color == COLOR_GREEN_CYAN || color == COLOR_CYAN || color == COLOR_BLUE ||
        color == COLOR_LIGHT_GREEN_CYAN|| color == COLOR_LIGHT_CYAN|| color == COLOR_LIGHT_BLUE) return 1;
    return 0;
}
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


int get_main_color_of_image(void * imgData, int imgW, int imgH, IMAGE_FORMAT format, const IMAGE_AREA * area, int * color_dict, int * sorted_indexes) {
    unsigned char * p = (unsigned char *)imgData;
    COLOR_RGB rgb;
    COLOR_HSV hsv;
    COLOR_YUV yuv;

    float avg_hsv[9][3] = {0}, n_total_pixel = 0;
    for (int i = 0; i < COLOR_UNDEFINED_S; i++) color_dict[i] = 0;
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
                YUVtoHSV100(&yuv, &hsv);
            } else if (format == IMAGE_FORMAT_NV21) {
                yuv.Y = p[y * imgW + x];
                yuv.U = p[(int)(imgW * imgH + (y / 2) * imgW + x - (x % 2))];
                yuv.V = p[(int)(imgW * imgH + (y / 2) * imgW + x - (x % 2) + 1)];
                YUVtoHSV100(&yuv, &hsv);
            }
            if (hsv.H >= 300) hsv.H -= 360;
            if (hsv.V <= 30) {
                color_dict[COLOR_BLACK_S]++;
                avg_hsv[COLOR_BLACK_S][0] += hsv.H;
                avg_hsv[COLOR_BLACK_S][1] += hsv.S;
                avg_hsv[COLOR_BLACK_S][2] += hsv.V;
            } else if (hsv.S <= 10)  {
                color_dict[COLOR_WHITE_S]++;
                avg_hsv[COLOR_WHITE_S][0] += hsv.H;
                avg_hsv[COLOR_WHITE_S][1] += hsv.S;
                avg_hsv[COLOR_WHITE_S][2] += hsv.V;
            } else if (hsv.H < 10 || hsv.H >= 300) {
                color_dict[COLOR_RED_S]++;
                avg_hsv[COLOR_RED_S][0] += hsv.H < 10 ? hsv.H: hsv.H - 360;
                avg_hsv[COLOR_RED_S][1] += hsv.S;
                avg_hsv[COLOR_RED_S][2] += hsv.V;
            } else if (hsv.H >= 10 && hsv.H < 41) {
                color_dict[COLOR_ORANGE_S]++;
                avg_hsv[COLOR_ORANGE_S][0] += hsv.H;
                avg_hsv[COLOR_ORANGE_S][1] += hsv.S;
                avg_hsv[COLOR_ORANGE_S][2] += hsv.V;
            } else if (hsv.H >= 41 && hsv.H < 68) {
                color_dict[COLOR_YELLOW_S]++;
                avg_hsv[COLOR_YELLOW_S][0] += hsv.H;
                avg_hsv[COLOR_YELLOW_S][1] += hsv.S;
                avg_hsv[COLOR_YELLOW_S][2] += hsv.V;
            } else if (hsv.H >= 68 && hsv.H < 165) {
                color_dict[COLOR_GREEN_S]++;
                avg_hsv[COLOR_GREEN_S][0] += hsv.H;
                avg_hsv[COLOR_GREEN_S][1] += hsv.S;
                avg_hsv[COLOR_GREEN_S][2] += hsv.V;
            } else if (hsv.H >= 165 && hsv.H < 200) {
                color_dict[COLOR_CYAN_S]++;
                avg_hsv[COLOR_CYAN_S][0] += hsv.H;
                avg_hsv[COLOR_CYAN_S][1] += hsv.S;
                avg_hsv[COLOR_CYAN_S][2] += hsv.V;
            } else if (hsv.H >= 200 && hsv.H < 245) {
                color_dict[COLOR_BLUE_S]++;
                avg_hsv[COLOR_BLUE_S][0] += hsv.H;
                avg_hsv[COLOR_BLUE_S][1] += hsv.S;
                avg_hsv[COLOR_BLUE_S][2] += hsv.V;
            } else if (hsv.H >= 245 && hsv.H < 300) {
                color_dict[COLOR_PURPLE_S]++;
                avg_hsv[COLOR_PURPLE_S][0] += hsv.H;
                avg_hsv[COLOR_PURPLE_S][1] += hsv.S;
                avg_hsv[COLOR_PURPLE_S][2] += hsv.V;
            }
        }
    }


    for (int i = 0; i < 9; i++) {
        if (color_dict[i] < 0.05 * (area->Y_End - area->Y_Start + 1) * (area->X_End - area->X_Start + 1)) {
            color_dict[i] = 0;
            for (int j = 0; j < 3; j++)	avg_hsv[i][j] = 0;
            continue;
        }
        for (int j = 0; j < 3; j++)	avg_hsv[i][j] /= color_dict[i];
    }

    //squeeze color_dict
    if (color_dict[COLOR_BLACK_S] > 0 && avg_hsv[COLOR_BLACK_S][2] > 15) { // squeeze with black
        for (int i = COLOR_RED_S; i <= COLOR_ORANGE_S; i++) {
            if (color_dict[i] == 0) continue;
            if (abs(avg_hsv[i][0] - avg_hsv[COLOR_BLACK_S][0]) <= 10 && avg_hsv[i][2] < 60) {
                avg_hsv[i][0] = (avg_hsv[i][0] * color_dict[i] + avg_hsv[COLOR_BLACK_S][0] * color_dict[COLOR_BLACK_S]) / (color_dict[i] + color_dict[COLOR_BLACK_S]);
                avg_hsv[i][1] = (avg_hsv[i][1] * color_dict[i] + avg_hsv[COLOR_BLACK_S][1] * color_dict[COLOR_BLACK_S]) / (color_dict[i] + color_dict[COLOR_BLACK_S]);
                avg_hsv[i][2] = (avg_hsv[i][2] * color_dict[i] + avg_hsv[COLOR_BLACK_S][2] * color_dict[COLOR_BLACK_S]) / (color_dict[i] + color_dict[COLOR_BLACK_S]);
                avg_hsv[COLOR_BLACK_S][0] = 0;
                avg_hsv[COLOR_BLACK_S][1] = 0;
                avg_hsv[COLOR_BLACK_S][2] = 0;
                color_dict[i] += color_dict[COLOR_BLACK_S];
                color_dict[COLOR_BLACK_S] = 0;
                break;
            }
        }
    }
    for (int i = COLOR_RED_S; i < COLOR_PURPLE_S; i++) { //close color
        if (color_dict[i] == 0 || color_dict[i + 1] == 0) continue;
        if (abs(avg_hsv[i][0] - avg_hsv[i + 1][0]) <= 10) {
            if (color_dict[i] >= color_dict[i + 1]) {
                avg_hsv[i][0] = (avg_hsv[i][0] * color_dict[i] + avg_hsv[i + 1][0] * color_dict[i + 1]) / (color_dict[i] + color_dict[i + 1]);
                avg_hsv[i][1] = (avg_hsv[i][1] * color_dict[i] + avg_hsv[i + 1][1] * color_dict[i + 1]) / (color_dict[i] + color_dict[i + 1]);
                avg_hsv[i][2] = (avg_hsv[i][2] * color_dict[i] + avg_hsv[i + 1][2] * color_dict[i + 1]) / (color_dict[i] + color_dict[i + 1]);
                avg_hsv[i + 1][0] = 0;
                avg_hsv[i + 1][1] = 0;
                avg_hsv[i + 1][2] = 0;
                color_dict[i] += color_dict[i + 1];
                color_dict[i + 1] = 0;
            } else {
                avg_hsv[i + 1][0] = (avg_hsv[i][0] * color_dict[i] + avg_hsv[i + 1][0] * color_dict[i + 1]) / (color_dict[i] + color_dict[i + 1]);
                avg_hsv[i + 1][1] = (avg_hsv[i][1] * color_dict[i] + avg_hsv[i + 1][1] * color_dict[i + 1]) / (color_dict[i] + color_dict[i + 1]);
                avg_hsv[i + 1][2] = (avg_hsv[i][2] * color_dict[i] + avg_hsv[i + 1][2] * color_dict[i + 1]) / (color_dict[i] + color_dict[i + 1]);
                avg_hsv[i][0] = 0;
                avg_hsv[i][1] = 0;
                avg_hsv[i][2] = 0;
                color_dict[i + 1] += color_dict[i];
                color_dict[i] = 0;
            }
        }
    }

    //set color index
    sorted_indexes[COLOR_BLACK_S] = COLOR_BLACK; // black

    if (avg_hsv[COLOR_WHITE_S][0] < 80) sorted_indexes[COLOR_WHITE_S] = COLOR_WARM_WHITE; // white
    else sorted_indexes[COLOR_WHITE_S] = COLOR_WHITE;

    if (color_dict[COLOR_RED_S] == 0) sorted_indexes[COLOR_RED_S] = COLOR_RED; //red
    else if ((avg_hsv[COLOR_RED_S][0] > -20 && avg_hsv[COLOR_RED_S][0] < 10) && avg_hsv[COLOR_RED_S][2] <= 40)	sorted_indexes[COLOR_RED_S] = COLOR_ROSEWOOD;
    else if (avg_hsv[COLOR_RED_S][0] < -17 || avg_hsv[COLOR_RED_S][1] <= 40) sorted_indexes[COLOR_RED_S] = COLOR_PINK;
    else sorted_indexes[COLOR_RED_S] = COLOR_RED;//red

    if (color_dict[COLOR_ORANGE_S] == 0) sorted_indexes[COLOR_ORANGE_S] = COLOR_ORANGE;
    else if (avg_hsv[COLOR_ORANGE_S][1] <= 40 && avg_hsv[COLOR_ORANGE_S][2] >= 50) sorted_indexes[COLOR_ORANGE_S] = COLOR_CHAMPAGNE;
    else if (avg_hsv[COLOR_ORANGE_S][2] <= 50) sorted_indexes[COLOR_ORANGE_S] = COLOR_COFFEE;
    else sorted_indexes[COLOR_ORANGE_S] = COLOR_ORANGE;

    if (avg_hsv[COLOR_YELLOW_S][1] <= 40 && avg_hsv[COLOR_YELLOW_S][2] >= 70) sorted_indexes[COLOR_YELLOW_S] = COLOR_LIGHT_YELLOW;
    else sorted_indexes[COLOR_YELLOW_S] = COLOR_YELLOW;

    if (avg_hsv[COLOR_GREEN_S][1] <= 40 && avg_hsv[COLOR_GREEN_S][2] >= 70) {
        if (avg_hsv[COLOR_GREEN_S][0] < 89) sorted_indexes[COLOR_GREEN_S] = COLOR_LIGHT_YELLOW_GREEN;
        else if (avg_hsv[COLOR_GREEN_S][0] > 141) sorted_indexes[COLOR_GREEN_S] = COLOR_LIGHT_GREEN_CYAN;
        else sorted_indexes[COLOR_GREEN_S] = COLOR_LIGHT_GREEN;
    }
    else {
        if (avg_hsv[COLOR_GREEN_S][0] < 89) sorted_indexes[COLOR_GREEN_S] = COLOR_YELLOW_GREEN;
        else if (avg_hsv[COLOR_GREEN_S][0] > 141) sorted_indexes[COLOR_GREEN_S] = COLOR_GREEN_CYAN;
        else sorted_indexes[COLOR_GREEN_S] = COLOR_GREEN;
    }

    if (avg_hsv[COLOR_CYAN_S][1] <= 40 && avg_hsv[COLOR_CYAN_S][2] >= 70) sorted_indexes[COLOR_CYAN_S] = COLOR_LIGHT_CYAN;
    else sorted_indexes[COLOR_CYAN_S] = COLOR_CYAN;

    if (avg_hsv[COLOR_BLUE_S][1] <= 40 && avg_hsv[COLOR_BLUE_S][2] >= 70) sorted_indexes[COLOR_BLUE_S] = COLOR_LIGHT_BLUE;
    else sorted_indexes[COLOR_BLUE_S] = COLOR_BLUE;

    if (avg_hsv[COLOR_PURPLE_S][1] <= 40 && avg_hsv[COLOR_PURPLE_S][2] >= 70) sorted_indexes[COLOR_PURPLE_S] = COLOR_LIGHT_PURPLE;
    else sorted_indexes[COLOR_PURPLE_S] = COLOR_PURPLE;

    sort_array_and_indexes_int(color_dict, sorted_indexes, 0, 8, 0);
    return 1;
}


Spectrum_Index get_2_base_color_spectrum_index(Color_Index c_max, Color_Index c_min) {
    if (if_color_warm(c_max) && if_color_warm(c_min)) return SPECTRUM_3000K;
    if (if_color_cold(c_max) && if_color_cold(c_min)) return SPECTRUM_4000K;
    if (c_max == COLOR_BLACK) {
        if (if_color_warm(c_min)) return SPECTRUM_3000K;
        if (if_color_neutral(c_min)) return SPECTRUM_3500K;
        if (if_color_cold(c_min)) return SPECTRUM_4000K;
    }
    if (c_min == COLOR_BLACK) {
        if (if_color_warm(c_max)) return SPECTRUM_3000K;
        if (if_color_neutral(c_max)) return SPECTRUM_3500K;
        if (if_color_cold(c_max)) return SPECTRUM_4000K;
    }
    return SPECTRUM_3500K;
}


Spectrum_Index getRecipeIndexOfImageROI(void * imgData, int imgW, int imgH, IMAGE_FORMAT format, const IMAGE_AREA * area) {
    int i, color_dict[9] = {0}, sorted_indexes[9], sum = 0, nonzero_count = 0;
    int c_max, c_min, c2, c_ww = 0, c_nw = 0, c_cw = 0;
    int color_priority[26] = {3, 1, 2, 24, 23, 19, 17, 15, 13, 9, 7, 5, 11, 21, 22, 18, 16, 14, 12, 8, 6, 4, 10, 20, 0, 25};
    get_main_color_of_image(imgData, imgW, imgH, format, area, color_dict, sorted_indexes);

    //for (i = 0; i < 9; i++) LOG_I("color %d has %d pixels", sorted_indexes[i], color_dict[i]);

    for (i = 0; i < 9; i++) sum += color_dict[i];
    if (color_dict[0] > sum * 0.7) return (Spectrum_Index)sorted_indexes[0];
    for (i = 0; i < 9; i++) {
        if (color_dict[i] > 50) nonzero_count++;
        else break;
    }
    if (nonzero_count == 2) {
        c_max = color_dict[0];
        c_min = color_dict[1];
        sum = c_max + c_min;
        if ((c_max - c_min) >= 0.25 * sum) return (Spectrum_Index)sorted_indexes[0];
        if ((c_max - c_min) >= 0.15 * sum) {
            if (color_priority[sorted_indexes[0]] > color_priority[sorted_indexes[1]]) return (Spectrum_Index)sorted_indexes[0];
            else return (Spectrum_Index)sorted_indexes[1];
        }
        else return get_2_base_color_spectrum_index((Color_Index)sorted_indexes[0], (Color_Index)sorted_indexes[1]);
    } else if (nonzero_count > 2) {
        sum = 0;
        if (nonzero_count > 4) nonzero_count = 4;
        for (i = 0; i < nonzero_count; i++) sum += color_dict[i];
        c_max = color_dict[0];
        c2 = color_dict[1];
        if ((c_max - c2) >= 0.3 * sum) return (Spectrum_Index)sorted_indexes[0];
        if (sorted_indexes[0] == COLOR_WHITE) return SPECTRUM_3500K;
        for (i = 0; i < nonzero_count; i++) {
            if (if_color_warm((Color_Index)sorted_indexes[i])) c_ww += color_dict[i];
            else if (if_color_neutral((Color_Index)sorted_indexes[i])) c_nw += color_dict[i];
            else if (if_color_cold((Color_Index)sorted_indexes[i])) c_cw += color_dict[i];
        }
        if (c_ww > 0.5 * sum) return SPECTRUM_3000K;
        if (c_nw > 0.5 * sum) return SPECTRUM_3500K;
        if (c_cw > 0.5 * sum) return SPECTRUM_4000K;
        return SPECTRUM_3500K;
    }
    return SPECTRUM_FULL;
}

int getRecipeIndexOfImageOnClick(void * imgData, int imgW, int imgH, IMAGE_FORMAT format, int clickX, int clickY){
    int radius = imgH / 10;
    if (radius < 20) radius = 20;
    int startX = clickX - radius < 0 ? 0: clickX - radius;
    int endX = clickX + radius >= imgW ? imgW - 1: clickX + radius;
    int startY = clickY - radius < 0 ? 0: clickY - radius;
    int endY = clickY + radius >= imgH ? imgH - 1: clickY + radius;

    IMAGE_AREA area = {startX, endX, startY, endY};
    return getRecipeIndexOfImageROI(imgData, imgW, imgH, format, &area);
}

int getRecipeIndexOfImageOnBox(void * imgData, int imgW, int imgH, IMAGE_FORMAT format, int startX, int startY, int endX, int endY){
    IMAGE_AREA area = {startX, endX, startY, endY};
    return getRecipeIndexOfImageROI(imgData, imgW, imgH, format, &area);
}
