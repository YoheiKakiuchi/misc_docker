#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <string.h>
#include <signal.h>

#include <sysexits.h>
#include <sys/time.h>

#define TIMEOUT 1000	/* 1 second timeout */

#include <winscard.h>

int main(int argc, char **argv[])
{
  LONG rv;
  SCARDCONTEXT hContext;
  SCARD_READERSTATE rgReaderStates[1];

  const char **readers = NULL;
  SCARD_READERSTATE *rgReaderStates_t = NULL;
  LPSTR mszReaders = NULL;

  DWORD dwReaders = 0;

  rgReaderStates[0].szReader = "\\\\?PnP?\\Notification";
  rgReaderStates[0].dwCurrentState = SCARD_STATE_UNAWARE;

  rv = SCardEstablishContext(SCARD_SCOPE_SYSTEM, NULL, NULL, &hContext);
  printf("0:rv = %lX %lX\n", rv,
         SCARD_S_SUCCESS);

  rv = SCardGetStatusChange(hContext, 0, rgReaderStates, 1);
  printf("1:rv = %lX\n", rv);

  // ( rgReaderStates[0].dwEventState & SCARD_STATE_UNKNOWN )

  rv = SCardListReaders(hContext, NULL, NULL, &dwReaders);
  printf("2:rv = %lX %d\n", rv, dwReaders);
  mszReaders = malloc(sizeof(char)*dwReaders);

  *mszReaders = '\0';
  rv = SCardListReaders(hContext, NULL, mszReaders, &dwReaders);
  printf("3:rv = %lX\n", rv);

  for(int j = 0; j < dwReaders; j ++) {
    printf("%x %c\n", mszReaders[j], mszReaders[j]);
  }
  int nbReaders = 0;
  char *ptr = mszReaders;
  while (*ptr != '\0') {
    //readers[nbReaders] = ptr;
    ptr += strlen(ptr)+1;
    nbReaders++;
    printf("%d %d %c\n", nbReaders, *ptr, *ptr);
  }
  readers = calloc(nbReaders+1, sizeof(char *));
  nbReaders = 0;
  ptr = mszReaders;
  while (*ptr != '\0') {
    readers[nbReaders] = ptr;
    ptr += strlen(ptr)+1;
    nbReaders++;
    printf("%d %d %c\n", nbReaders, *ptr, *ptr);
  }

  printf("readers = %d\n", nbReaders);

  rgReaderStates_t = calloc(nbReaders+1, sizeof(* rgReaderStates_t));
  //rv = SCardGetStatusChange(hContext, TIMEOUT, rgReaderStates_t, nbReaders);
  //printf("4:rv = %lX\n", rv);

  for (int i=0; i<nbReaders; i++) {
    rgReaderStates_t[i].szReader = readers[i];
    rgReaderStates_t[i].dwCurrentState = SCARD_STATE_UNAWARE;
    rgReaderStates_t[i].cbAtr = sizeof rgReaderStates_t[i].rgbAtr;
  }
  rgReaderStates_t[nbReaders].szReader = "\\\\?PnP?\\Notification";
  rgReaderStates_t[nbReaders].dwCurrentState = SCARD_STATE_UNAWARE;

  rv = SCardGetStatusChange(hContext, TIMEOUT, rgReaderStates_t, nbReaders+1);
  printf("5:rv = %lX\n", rv);

  for (int current_reader = 0; current_reader < nbReaders; current_reader++) {
    if (rgReaderStates_t[current_reader].dwEventState & SCARD_STATE_CHANGED) {
      /* If something has changed the new state is now the current 
       * state */
      rgReaderStates_t[current_reader].dwCurrentState = rgReaderStates_t[current_reader].dwEventState;
    } else {
      printf("cont %lx\n", rgReaderStates_t[current_reader].dwEventState);
      /* If nothing changed then skip to the next reader */
      continue;
    }

    printf(" Reader %d: %s\n", current_reader,
           rgReaderStates_t[current_reader].szReader);

    /* Event number */
    printf("  Event number: %ld\n",
           rgReaderStates_t[current_reader].dwEventState >> 16);

    /* Dump the full current state */
    printf("  Card state: ");
    if (rgReaderStates_t[current_reader].dwEventState &
        SCARD_STATE_UNAVAILABLE)
      printf("Status unavailable, ");

    if (rgReaderStates_t[current_reader].dwEventState &
        SCARD_STATE_EMPTY)
      printf("Card removed, ");

    if (rgReaderStates_t[current_reader].dwEventState &
        SCARD_STATE_PRESENT)
      printf("Card inserted, ");

    if (rgReaderStates_t[current_reader].dwEventState &
        SCARD_STATE_ATRMATCH)
      printf("ATR matches card, ");

    if (rgReaderStates_t[current_reader].dwEventState &
        SCARD_STATE_EXCLUSIVE)
      printf("Exclusive Mode, ");

    if (rgReaderStates_t[current_reader].dwEventState &
        SCARD_STATE_INUSE)
      printf("Shared Mode, ");

    if (rgReaderStates_t[current_reader].dwEventState &
        SCARD_STATE_MUTE)
      printf("Unresponsive card, ");

    printf("\n");

    SCARDHANDLE hCard;
    DWORD dwActiveProtocol;
    rv = SCardConnect(hContext, rgReaderStates_t[current_reader].szReader,
                      SCARD_SHARE_SHARED,
                      SCARD_PROTOCOL_T0 | SCARD_PROTOCOL_T1, &hCard, &dwActiveProtocol);
    printf("6:rv = %lX\n", rv);

    const SCARD_IO_REQUEST *pioSendPci;
    switch (dwActiveProtocol) {
    case SCARD_PROTOCOL_T0:
      printf("protocol T0\n");
      pioSendPci = SCARD_PCI_T0;
      break;
    case SCARD_PROTOCOL_T1:
      printf("protocol T1\n");
      pioSendPci = SCARD_PCI_T1;
      break;
    case SCARD_PROTOCOL_RAW:
      printf("protocol RAW\n");
      pioSendPci = SCARD_PCI_RAW;
      break;
    default:
      fprintf(stderr, "Unknown protocol\n");
      return -1;
    }

    {
      BYTE pbSendBuffer[] = {0xFF, 0xCA, 0x00, 0x00, 0x00};
      BYTE pbRecvBuffer[256+2];
      DWORD dwSendLength = sizeof(pbSendBuffer);
      DWORD dwRecvLength = sizeof(pbRecvBuffer);

      rv = SCardTransmit(hCard, pioSendPci, pbSendBuffer, dwSendLength,
                         NULL, pbRecvBuffer, &dwRecvLength);
      printf("transmit:rv = %lX\n", rv);

      for(int i = 0; i < dwRecvLength; i++) {
        printf("%d %02x %c\n", i, pbRecvBuffer[i], pbRecvBuffer[i]);
      }
    }

    rv = SCardDisconnect(hCard, SCARD_UNPOWER_CARD);
    printf("8:rv = %lX\n", rv);
  }

  rv = SCardReleaseContext(hContext);
  printf("last:rv = %lX\n", rv);
}
