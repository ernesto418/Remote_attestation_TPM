/**
* MIT License
*
* Copyright (c) 2020 Infineon Technologies AG
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE
*/

#include <stdio.h>
#include <curl/curl.h>
#include <json-c/json.h>
#include <string.h>
#include <libconfig.h>

unsigned char* hexstr_to_char(const char* hexstr)
{
    size_t len = strlen(hexstr);
    size_t final_len = len / 2;
    unsigned char* chrs = (unsigned char*)malloc((final_len+1) * sizeof(*chrs));
    for (size_t i=0, j=0; j<final_len; i+=2, j++)
        chrs[j] = (hexstr[i] % 32 + 9) % 25 * 16 + (hexstr[i+1] % 32 + 9) % 25;
    chrs[final_len] = '\0';
    return chrs;
}



static char *fMalloc(FILE *fd, size_t *sz) {
  fseek(fd, 0, SEEK_END);
  *sz = ftell(fd);
  rewind(fd);
  return malloc(*sz);  
}

static char *fByteAry2HexStr(char *ba, size_t size) {
  int i = 0, j = 0;
  char *str = malloc((size*2)+1);
  
  for (; i<size; i++) {
    sprintf(&str[j], "%02x", ba[i]);
    j+=2;
  }
  str[j] = '\0';
  return str;
}

static size_t fRespBody(void *ptr, size_t size, size_t nmemb, void *stream) {
  if (size != 1) {
    printf("element size error!");
  }
  {
    json_object *json, *status, *data;
    enum json_tokener_error jerr = json_tokener_error_depth;

    json = json_tokener_parse_verbose((char *) ptr, &jerr);
    if (jerr != json_tokener_success) {
      printf("Failed to parse json string\n");
      json_object_put(json);
      return nmemb*size;
    }

    //printf("%s\n", json_object_to_json_string(json));

    status = json_object_object_get(json, "status");
    if (status != NULL) {
      if (!strcmp(json_object_get_string(status), "ok")) {
        data = json_object_object_get(json, "data");
          if ( data != NULL && json_object_is_type(data, json_type_string)) {
            const char *str = json_object_get_string(data);
            unsigned char *str_byte = hexstr_to_char(str);
                  FILE *fd = NULL;

                if ((fd = fopen("../certificates/csr.bin", "wb")) != NULL) {
                    fwrite(str_byte, strlen(str)/2, 1, fd);
                    fclose(fd);
                    printf("written to ../certificates/csr.bin\n");
            } else {
            printf("could not open file \n %s",json_object_to_json_string(json));}
          } else {
            printf("data = null or data is not string\n %s",json_object_to_json_string(json));
          }
      }
      else {
        printf("status no ok: \n %s",json_object_to_json_string(json));
      }
    } else {
      printf("status = null\n");
    }

    json_object_put(json);
  }
  return nmemb*size;
}

static size_t fRespHeader(void *ptr, size_t size, size_t nmemb, void *stream) {
  if (size != 1) {
    printf("element size error!");
  }
  //printf("%s\n", (char *) ptr);
  return nmemb*size;
}

int main(void)
{
  CURLcode res;
  const char *server = NULL;
  const char *username = NULL;
  const char *signature_path = NULL;


  json_object *intArray = NULL, *strArray = NULL;
  config_t cfg;
  const config_setting_t *c1 = NULL;
  const config_setting_t *c2 = NULL;
  size_t pcrs_sha1 = 0;
  size_t pcrs_sha2 = 0;
  
  // To be freed on exit
  CURL *curl = NULL;
  config_t *cf = NULL;
  char *signature = NULL;

  json_object *json = NULL;
  struct curl_slist *headers = NULL;

  cf = &cfg;
  config_init(cf);

  if (!config_read_file(cf, "config.cfg")) {
    printf("config.cfg file bad format\n");
    goto exit;
  }

  if (!config_lookup_string(cf, "auth.server", &server)) {
    printf("server url is not defined\n");
    goto exit;
  }

  if (!config_lookup_string(cf, "auth.username", &username)) {
    printf("username is not defined\n");
    goto exit;
  }











  /**
   * Read Signature of Ucsr
   */
  if (!config_lookup_string(cf, "CSR.file_signature", &signature_path)) {
    printf("file_signature is not defined\n");
    goto exit;
  }

  {
    FILE *fd = NULL;
    if ((fd = fopen(signature_path, "rb")) != NULL) {
      size_t sz = 0;
      char *buf = fMalloc(fd, &sz);
      printf("UCSR's signature size: %d Bytes\n",sz);
      fread(buf, sizeof(char), sz, fd);
      fclose(fd);
      signature = fByteAry2HexStr(buf, sz);
      free(buf);
      //printf("%s\n", SeKPub);
    } else {
      printf("UCSR's signature file not found\n");
      goto exit;
    }
  }



  /**
   * Build JSON
   */
  curl = curl_easy_init();
  if(curl) {
    char *url = NULL;

    url = malloc(strlen("/csr") + strlen(server) + 1);
    url[0] = '\0';
    strcat(url, server);
    strcat(url,"/csr");

    curl_easy_setopt(curl, CURLOPT_URL, url);
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0L);
    curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "POST");

    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
    curl_easy_setopt(curl, CURLOPT_HEADERFUNCTION, fRespHeader);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, fRespBody);

    headers = curl_slist_append(headers, "Accept: application/json");
    headers = curl_slist_append(headers, "Content-Type: application/json");
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);

    free(url);

    json = json_object_new_object();
    json_object_object_add(json, "username", json_object_new_string(username));
    json_object_object_add(json, "signature", json_object_new_string(signature));



    curl_easy_setopt(curl, CURLOPT_POSTFIELDS, json_object_to_json_string(json));
    // Do not verify SSL server cert since we will be using self-sign cert for localhost
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 0);
 
    res = curl_easy_perform(curl);
    if(res != CURLE_OK)
      fprintf(stderr, "curl_easy_perform() failed: %s\n",
              curl_easy_strerror(res));
  }

exit:
  if (curl != NULL) curl_easy_cleanup(curl);
  if (cf != NULL) config_destroy(cf);
  if (json != NULL) json_object_put(json);
  if (headers != NULL) curl_slist_free_all(headers);
  if (signature != NULL) free(signature);


  return 0;
}
