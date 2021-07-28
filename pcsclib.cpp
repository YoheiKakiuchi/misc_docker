#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <string.h>
#include <signal.h>

#include <string>
#include <vector>

#include <winscard.h>

class PCSClib
{
public:
  PCSClib (int index = 0) : established(false), timeout(1000)
  {
    {
      bool res;
      res = establishContext();
      if (!res) {
        printf("failed establish\n");
      }
    }
    if (established) {
      bool res;
      std::vector<std::string> list_readers;
      res = listReaders(list_readers);
      if (!res){
        printf("failed list\n");
      } else {
        if (list_readers.size() > index) {
          current_reader = list_readers[index];
        }
      }
    }
  }
  PCSClib (std::string &devname) : established(false), timeout(1000)
  {

  }

  ~PCSClib() {
    printf("~PCSClib\n");
    if (established) {
      LONG rv;
      rv = SCardReleaseContext(_Context);
      if (!resolveReturnValue(rv)) {
        printf("~Release failed\n");
      //
      }
      current_reader.resize(0);
      established = false;
      printf("~Release\n");
    }
  }

  bool established;
  int timeout;
  SCARDCONTEXT _Context;

  std::string current_reader;

  bool isEstablished() {
    return established;
  }
  bool isReader() {
    return !current_reader.empty();
  }
  bool canWait() {
    return isEstablished() && isReader();
  }

  bool establishContext() {
    LONG rv;
    rv = SCardEstablishContext(SCARD_SCOPE_SYSTEM, NULL, NULL, &_Context);
    if (!resolveReturnValue(rv)) {
      //
      printf("establish failed %lX\n", rv);
      return false;
    }
    established = true;
    return established;
  }

  bool listReaders(std::vector<std::string> &list_readers) {
    DWORD readsize = 0;
    char *reader_str;
    LONG rv;
    bool result = false;
    rv = SCardListReaders(_Context, NULL, NULL, &readsize);
    if (!resolveReturnValue(rv)) {
      //
      printf("fail 0\n");
      return false;
    }

    reader_str = (char *)malloc(sizeof(char)* readsize);
    *reader_str = '\0';
    rv = SCardListReaders(_Context, NULL, reader_str, &readsize);
    if (!resolveReturnValue(rv)) {
      //
      printf("fail 1\n");
      return false;
    }
    int num_readers = 0;
    int start_str = 0;
    for(int i = 0; i < readsize - 1; i++) {
      if (reader_str[i] == '\0') {
        if (i - start_str != 0) {
          result = true;
          num_readers++;
          std::string str(reader_str + start_str, i - start_str);
          list_readers.push_back(str);
          start_str = i+1;
        }
      }
    }
    return result;
  }

  bool getStatusChange(SCARD_READERSTATE &readerState, bool initialize = false) {
    if ( current_reader.size() == 0 ) {
      return false;
    }

    if (initialize) {
      //SCARD_READERSTATE readerState;
      readerState.szReader = current_reader.c_str();
      readerState.dwCurrentState = SCARD_STATE_UNAWARE;
      readerState.cbAtr = sizeof readerState.rgbAtr;
    }

    LONG rv;
    rv = SCardGetStatusChange(_Context, timeout, &readerState, 1);
    if (!resolveReturnValue(rv)) {
      //
      return false;
    }

    return true;
  }

  bool getCardID (unsigned long &id) {
    SCARDHANDLE hCard;
    DWORD dwActiveProtocol;
    LONG rv;
    rv = SCardConnect(_Context, current_reader.c_str(),
                      SCARD_SHARE_SHARED,
                      SCARD_PROTOCOL_T0 | SCARD_PROTOCOL_T1, &hCard, &dwActiveProtocol);
    if (!resolveReturnValue(rv)) {
      //
      return false;
    }
    const SCARD_IO_REQUEST *pioSendPci;
    switch (dwActiveProtocol) {
    case SCARD_PROTOCOL_T0:
      //printf("protocol T0\n");
      pioSendPci = SCARD_PCI_T0;
      break;
    case SCARD_PROTOCOL_T1:
      //printf("protocol T1\n");
      pioSendPci = SCARD_PCI_T1;
      break;
    case SCARD_PROTOCOL_RAW:
      //printf("protocol RAW\n");
      pioSendPci = SCARD_PCI_RAW;
      break;
    default:
      //fprintf(stderr, "Unknown protocol\n");
      return false;
    }

    BYTE pbSendBuffer[] = {0xFF, 0xCA, 0x00, 0x00, 0x00}; // read
    BYTE pbRecvBuffer[256+2];
    DWORD dwSendLength = sizeof(pbSendBuffer);
    DWORD dwRecvLength = sizeof(pbRecvBuffer);

    rv = SCardTransmit(hCard, pioSendPci, pbSendBuffer, dwSendLength,
                       NULL, pbRecvBuffer, &dwRecvLength);
    if (!resolveReturnValue(rv)) {
      //
      return false;
    }
    //for(int i = 0; i < dwRecvLength; i++) {
    //  printf("%d %02x %c\n", i, pbRecvBuffer[i], pbRecvBuffer[i]);
    //}
    if (dwRecvLength >= 8) {
      id = 0L;
      for (int i = 0; i < 8; i++) {
        unsigned long val = pbRecvBuffer[i];
        id |=  val << 8 * (7 - i);
      }
    }

    rv = SCardDisconnect(hCard, SCARD_UNPOWER_CARD);
    if (!resolveReturnValue(rv)) {
      //
      return false;
    }
    return true;
  }

  bool resolveReturnValue(LONG val, bool print=false, bool verbose=false) {
    switch (val) {
    case SCARD_S_SUCCESS: //Successful (SCARD_S_SUCCESS)
      return true;
      break;
    case SCARD_E_NO_SERVICE: //Server is not running (SCARD_E_NO_SERVICE)
      return false;
      break;
    case SCARD_E_INVALID_PARAMETER:  // rgReaderStates is NULL and cReaders > 0 (SCARD_E_INVALID_PARAMETER)
      return false;
      break;
    case SCARD_E_INVALID_VALUE:// Invalid States, reader name, etc (SCARD_E_INVALID_VALUE)
      return false;
      break;
    case SCARD_E_INVALID_HANDLE://Invalid hContext handle (SCARD_E_INVALID_HANDLE)
      return false;
      break;
    case SCARD_E_READER_UNAVAILABLE://The reader is unavailable (SCARD_E_READER_UNAVAILABLE)
      return false;
      break;
    case SCARD_E_UNKNOWN_READER://The reader name is unknown (SCARD_E_UNKNOWN_READER)
      return false;
      break;
    case SCARD_E_TIMEOUT://The user-specified timeout value has expired (SCARD_E_TIMEOUT)
      return false;
      break;
    case SCARD_E_CANCELLED://
      return false;
      break;
    }
    // invalid
    return false;
  }

  bool waitAndGetID() {
    SCARD_READERSTATE readerState;
    bool res;
    res = getStatusChange(readerState, true);
    while(true) {
      if (res) {
        if (readerState.dwEventState & SCARD_STATE_CHANGED) {
          readerState.dwCurrentState = readerState.dwEventState;
          if (readerState.dwEventState & SCARD_STATE_PRESENT) {
            unsigned long id;
            bool res_id;
            res_id = getCardID(id);
            if (res_id) {
              printf("getID: %lX\n", id);
            }
          }
          if (readerState.dwEventState & SCARD_STATE_EMPTY) {
            printf("card removed\n");
          }
        }
      }
      res = getStatusChange(readerState);
    }

    return true;
  }
};

#if 0
typedef struct
{
  const char *szReader;
  void *pvUserData;
  DWORD dwCurrentState;
  DWORD dwEventState;
  DWORD cbAtr;
  unsigned char rgbAtr[MAX_ATR_SIZE];
} SCARD_READERSTATE;
#endif

extern "C" {
  long create_pcsclib(int index) {
    PCSClib *lib = new PCSClib(index);
    if (!!lib) {
      return (long)((void *)lib);
    } else {
      return 0;
    }
  }
  int delete_pcsclib(long ptr) {
    PCSClib *lib = (PCSClib *)((void *)ptr);
    delete lib;
    return 1;
  }
  int canwait_pcsclib(long ptr) {
    PCSClib *lib = (PCSClib *)((void *)ptr);
    return (int)(lib->canWait());
  }
  int readername_pcsclib(long ptr, char *reader, int size) {
    PCSClib *lib = (PCSClib *)((void *)ptr);
    for(int i = 0; i < lib->current_reader.size() && i < size; i++) {
      reader[i] = lib->current_reader[i];
    }
    return lib->current_reader.size();
  }
  int get_status_change_pcsclib(long ptr, SCARD_READERSTATE *readerState) {
    PCSClib *lib = (PCSClib *)((void *)ptr);
    return (int)(lib->getStatusChange(*readerState));
  }
  int initialize_status_pcsclib(char *str, SCARD_READERSTATE *readerState) {
    readerState->szReader = str;
    readerState->dwCurrentState = SCARD_STATE_UNAWARE;
    readerState->cbAtr = sizeof readerState->rgbAtr;
    readerState->pvUserData = NULL;
    return 1;
  }
  long read_status_pcsclib(SCARD_READERSTATE *readerState) {
    if (readerState->dwEventState & SCARD_STATE_CHANGED) {
      readerState->dwCurrentState = readerState->dwEventState;
    }
    long res = readerState->dwEventState;
    return res;
  }

  unsigned long get_card_id_pcsclib(long ptr) {
    PCSClib *lib = (PCSClib *)((void *)ptr);
    unsigned long id;
    bool res_id = lib->getCardID(id);
    if (!res_id) {
      id = 0;
    }
    return id;
  }
}

#if 0
int main(int argc, char **argv)
{
  PCSClib lib;

  if (lib.isEstablished() &&
      lib.isReader()) {
    lib.waitAndGetID();
  }
}
#endif
