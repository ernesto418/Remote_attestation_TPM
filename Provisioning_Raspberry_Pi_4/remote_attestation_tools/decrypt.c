#include <openssl/conf.h>
#include <openssl/evp.h>
#include <openssl/err.h>
#include <stdio.h>
#include <curl/curl.h>
#include <json-c/json.h>
#include <string.h>
#include <libconfig.h>



void handleErrors(void)
{
    ERR_print_errors_fp(stderr);
    abort();
}

static char *fMalloc(FILE *fd, size_t *sz) {
  fseek(fd, 0, SEEK_END);
  *sz = ftell(fd);
  rewind(fd);
  return malloc(*sz);  
}


int decrypt(unsigned char *ciphertext, int ciphertext_len, unsigned char *key,
            unsigned char *iv, unsigned char *plaintext)
{
    EVP_CIPHER_CTX *ctx;

    int len;

    int plaintext_len;

    /* Create and initialise the context */
    if(!(ctx = EVP_CIPHER_CTX_new()))
        handleErrors();

    /*
     * Initialise the decryption operation. IMPORTANT - ensure you use a key
     * and IV size appropriate for your cipher
     * In this example we are using 256 bit AES (i.e. a 256 bit key). The
     * IV size for *most* modes is the same as the block size. For AES this
     * is 128 bits
     */
    if(1 != EVP_DecryptInit_ex(ctx, EVP_aes_256_cbc(), NULL, key, iv))
        handleErrors();

    /*
     * Provide the message to be decrypted, and obtain the plaintext output.
     * EVP_DecryptUpdate can be called multiple times if necessary.
     */
    if(1 != EVP_DecryptUpdate(ctx, plaintext, &len, ciphertext, ciphertext_len))
        handleErrors();
    plaintext_len = len;

    /*
     * Finalise the decryption. Further plaintext bytes may be written at
     * this stage.
     */
    if(1 != EVP_DecryptFinal_ex(ctx, plaintext + len, &len))
        handleErrors();
    plaintext_len += len;

    /* Clean up */
    EVP_CIPHER_CTX_free(ctx);

    return plaintext_len;
}
unsigned char *base64_decode(char* b64message, size_t *decode_len)
{
    BIO *bio = NULL, *b64 = NULL;
    unsigned char *buffer = NULL;

    size_t msglen = strlen(b64message);
    char b64message_[msglen];
    if(msglen == 0) goto cleanup;

    strcpy(b64message_, b64message);
    strcat(b64message_,"\n");

    bio = BIO_new_mem_buf(b64message_, -1);

    if(bio == NULL) goto cleanup;
    b64 = BIO_new(BIO_f_base64());
    if(b64 == NULL) goto cleanup;

    // New lines should't matter
    BIO_set_flags(bio, BIO_FLAGS_BASE64_NO_NL);

    bio = BIO_push(b64, bio);
    // The maximum possible length, after accounting for padding and CR+LF is msglen*3/4
    buffer = (unsigned char*) malloc(sizeof(char)*(msglen*3)/4);
    if (buffer == NULL) goto cleanup;

    *decode_len = (size_t) BIO_read(bio, buffer, (int) msglen);

cleanup:
    BIO_free_all(bio);
    return buffer;
}


int main (void)
{
    const char *secret_path = NULL;
        const char *secret_path_2 = NULL;
    const char *ciphertext_path = NULL;
        const char *iv_v = NULL;
        config_t cfg;
    
    
    // To be freed on exit
    char *to_decode_key = NULL;
    config_t *cf = NULL;
    unsigned char *key = NULL;
    unsigned char *key_2 = NULL;
    unsigned char *iv_encoded = NULL;
    unsigned char *iv = NULL;
    unsigned char *ciphertext;
    size_t len_key;
    size_t len_iv;
    size_t len_ciphertext;
    
    cf = &cfg;
    config_init(cf);
    
    if (!config_read_file(cf, "config.cfg")) {
      printf("config.cfg file bad format\n");
      goto exit;
    }
    
    
    /**
   * Read key in bin
   */
  if (!config_lookup_string(cf, "KCV.file_secretkey_2", &secret_path_2)) {
    printf("file_secretkey is not defined\n");
    goto exit;
  }

 
  
    {
    FILE *fd = NULL;
    if ((fd = fopen(secret_path_2, "rb")) != NULL) {
      size_t sz = 0;
      key_2 = fMalloc(fd, &sz);
      printf("ciphertext in base64 size: %d Bytes\n",sz);
      fread(key_2, sizeof(char), sz, fd);
      fclose(fd);
      //printf("%s\n", template);
    } else {
      printf("Secret in bin not found\n");
      goto exit;
    }
  }
    
    
    
    

    /**
   * Read key in base64
   */
   /*
  if (!config_lookup_string(cf, "KCV.file_secretkey", &secret_path)) {
    printf("file_secretkey is not defined\n");
    goto exit;
  }

 
  
    {
    FILE *fd = NULL;
    if ((fd = fopen(secret_path, "rb")) != NULL) {
      size_t sz = 0;
      char *buf = fMalloc(fd, &sz);
      printf("ciphertext in base64 size: %d Bytes\n",sz);
      fread(buf, sizeof(char), sz, fd);
      fclose(fd);
      key = base64_decode(buf, &len_key);
      free(buf);
      //printf("%s\n", template);
    } else {
      printf("Secret in base64 not found\n");
      goto exit;
    }
  }
  */
  
  

    /**
   * Read IV in base64
   */
  if (!config_lookup_string(cf, "KCV.iv", &iv_v)) {
    printf("file_secretkey is not defined\n");
    goto exit;
  }
    iv_encoded = malloc(128);
    for (int i =0;i<128;i++){
        iv_encoded[i] = iv_v[i];
    }
    iv= base64_decode(iv_encoded, &len_iv);


    /**
   * Read ciphertext in base64
   */

  if (!config_lookup_string(cf, "KCV.file_ciphertext", &ciphertext_path)) {
    printf("file_ciphertext is not defined\n");
    goto exit;
  }

  {
    FILE *fd = NULL;
    if ((fd = fopen(ciphertext_path, "rb")) != NULL) {
      size_t sz = 0;
      char *buf = fMalloc(fd, &sz);
      printf("ciphertext in base64 size: %d Bytes\n",sz);
      fread(buf, sizeof(char), sz, fd);
      fclose(fd);
      ciphertext = base64_decode(buf, &len_ciphertext);
      free(buf);
      //printf("%s\n", template);
    } else {
      printf("ciphertext in base64 not found\n");
      goto exit;
    }
  }


    /*
     * Buffer for ciphertext. Ensure the buffer is long enough for the
     * ciphertext which may be longer than the plaintext, depending on the
     * algorithm and mode.
     */
    

    /* Buffer for the decrypted text */
    unsigned char decryptedtext[2048];

    int decryptedtext_len;


        for (int i=0; i <32 ;i++){
        printf("%x", *(key_2+i));
    }
    printf("\n");
    decryptedtext_len = decrypt(ciphertext, len_ciphertext, key_2, iv,
                                decryptedtext);

    /* Add a NULL terminator. We are expecting printable text */
    decryptedtext[decryptedtext_len] = '\0';

    /* Show the decrypted text */
    printf("Decrypted text is:\n");
    printf("%s\n", decryptedtext);
    
    
    /* Writing the key in AuthPuK.pem */
    {
    FILE *fd = NULL;
    if ((fd = fopen("./AuthPuK.pem", "wb")) != NULL) {
    fwrite(decryptedtext, decryptedtext_len, 1, fd);
    fclose(fd);
    printf("written to ./AESkey.credential\n");
    }
    
    
    
    
    }

exit:
  if (cf != NULL) config_destroy(cf);
  if (to_decode_key != NULL) free(to_decode_key);
  if (iv_encoded != NULL) free(iv_encoded);
  if (key != NULL) free(key);
  if (iv != NULL) free(iv);
  if (ciphertext != NULL) free(ciphertext);


  return 0;

}
