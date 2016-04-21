//====================================================================================
//                       kkconv.h
//                            by Shinsuke MORI
//                            Last change : 4 June 1999
//====================================================================================

// 機  能 : 仮名漢字変換エージェントの定数
//
// 注意点 : なし


//------------------------------------------------------------------------------------
//                       define
//------------------------------------------------------------------------------------

#ifndef _kkconv_h
#define _kkconv_h


//------------------------------------------------------------------------------------
//                       キーに対応する定数 (cf. $ANTHY/src-util/agent.c)
//------------------------------------------------------------------------------------

const U_INT4 KEY_SHIFT  = 0x00010000;
const U_INT4 KEY_CTRL   = 0x00020000;
const U_INT4 KEY_ALT    = 0x00040000;

const S_CHAR KEY_SPACE  = ' ';
const S_CHAR KEY_OPAR   = '(';
const S_CHAR KEY_CPAR   = ')';

const U_INT4 KEY_ENTER     = 0x00000100;
const U_INT4 KEY_DELETE    = 0x00000200;
const U_INT4 KEY_LEFT      = 0x00000300;
const U_INT4 KEY_RIGHT     = 0x00000400;
const U_INT4 KEY_ESC       = 0x00000500;
const U_INT4 KEY_BACKSPACE = 0x00000600;
const U_INT4 KEY_UP        = 0x00000700;
const U_INT4 KEY_DOWN      = 0x00000800;

const U_INT4 KEY_CTRL_A      = (KEY_CTRL  | 'A');
const U_INT4 KEY_CTRL_E      = (KEY_CTRL  | 'E');
const U_INT4 KEY_CTRL_J      = (KEY_CTRL  | 'J');
const U_INT4 KEY_CTRL_K      = (KEY_CTRL  | 'K');
const U_INT4 KEY_CTRL_H      = (KEY_CTRL  | 'H');
const U_INT4 KEY_CTRL_D      = (KEY_CTRL  | 'D');
const U_INT4 KEY_SHIFT_LEFT  = (KEY_SHIFT | KEY_LEFT);
const U_INT4 KEY_SHIFT_RIGHT = (KEY_SHIFT | KEY_RIGHT);


//------------------------------------------------------------------------------------
//                       コマンドに対応する定数
//------------------------------------------------------------------------------------

enum CMNDTYPE{
    /* ハイレベルコマンド */
    CMDH_IGNORE_ICTXT,
    CMDH_GETPREEDIT,
    CMDH_SELECT_CONTEXT,
    CMDH_RELEASE_CONTEXT,
    CMDH_MAP_EDIT,
    CMDH_MAP_SELECT,
    CMDH_GET_CANDIDATE,
    CMDH_SELECT_CANDIDATE,
    CMDH_CHANGE_TOGGLE,
    CMDH_MAP_CLEAR,
    CMDH_SET_BREAK_INTO_ROMAN,
    CMDH_SET_PREEDIT_MODE,
    CMDH_PRINT_CONTEXT,

    /* キーコマンド */
    CMD_SPACE = 1000,
    CMD_ENTER,
    CMD_BACKSPACE, 
    CMD_DELETE,
    CMD_UP,
    CMD_ESC,
    CMD_SHIFTARROW,
    CMD_ARROW,
    CMD_KEY,
    CMD_GOBOL,
    CMD_GOEOL,
    CMD_CUT
};

static struct key_name_table {
  const char* name;
  int code;
  int is_modifier;
} key_name_table[] = {
  {"shift",     KEY_SHIFT,     1},
  {"ctrl",      KEY_CTRL,      1},
  {"alt",       KEY_ALT,       1},

  {"space",     KEY_SPACE,     0},
  {"opar",      KEY_OPAR,      0},
  {"cpar",      KEY_CPAR,      0},
  {"enter",     KEY_ENTER,     0},
  {"esc",       KEY_ESC,       0},
  {"backspace", KEY_BACKSPACE, 0},
  {"delete",    KEY_DELETE,    0},
  {"left",      KEY_LEFT,      0},
  {"right",     KEY_RIGHT,     0},
  {"up",        KEY_UP,        0},

  {NULL,        0,             0}
};


//------------------------------------------------------------------------------------
//                       endif
//------------------------------------------------------------------------------------

#endif


//====================================================================================
//                       END
//====================================================================================
