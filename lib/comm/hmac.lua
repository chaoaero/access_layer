local ffi = require "ffi"

local ffi_new = ffi.new
local ffi_str = ffi.string
local C = ffi.C
local setmetatable = setmetatable
local error = error

local _M = {_VERSION = '0.01' }

local mt = { __index = _M }


ffi.cdef[[
typedef struct engine_st ENGINE;
typedef struct env_md_st EVP_MD;
typedef struct evp_pkey_ctx_st EVP_PKEY_CTX;
typedef struct env_md_ctx_st EVP_MD_CTX;
struct env_md_ctx_st
{
    const EVP_MD *digest;
	ENGINE *engine;
	unsigned long flags;
	void *md_data;
	EVP_PKEY_CTX *pctx;
	int (*update)(EVP_MD_CTX *ctx,const void *data,size_t count);
}EVP_MD_CTX;
enum {
    HMAC_MAX_MD_CBLOCK = 128
};

const EVP_MD *EVP_md5(void);
const EVP_MD *EVP_sha(void);
const EVP_MD *EVP_sha1(void);
const EVP_MD *EVP_sha224(void);
const EVP_MD *EVP_sha256(void);
const EVP_MD *EVP_sha384(void);
const EVP_MD *EVP_sha512(void);

typedef struct hmac_ctx_st
{
const EVP_MD *md;
EVP_MD_CTX md_ctx;
EVP_MD_CTX i_ctx;
EVP_MD_CTX o_ctx;
unsigned int key_length;
unsigned char key[HMAC_MAX_MD_CBLOCK];
} HMAC_CTX;

void HMAC_CTX_init(HMAC_CTX *ctx);
void HMAC_CTX_cleanup(HMAC_CTX *ctx);
int HMAC_Init_ex(HMAC_CTX *ctx, const void *key, int len,
const EVP_MD *md, ENGINE *impl);
int HMAC_Update(HMAC_CTX *ctx, const unsigned char *data, size_t len);
int HMAC_Final(HMAC_CTX *ctx, unsigned char *md, unsigned int *len);
unsigned char *HMAC(const EVP_MD *evp_md, const void *key, int key_len,
const unsigned char *d, size_t n, unsigned char *md,
unsigned int *md_len);
int HMAC_CTX_copy(HMAC_CTX *dctx, HMAC_CTX *sctx);

void HMAC_CTX_set_flags(HMAC_CTX *ctx, unsigned long flags);

]]

local ctx_ptr_type = ffi.typeof("HMAC_CTX[1]")

hash = {
    md5 = C.EVP_md5(),
    sha1 = C.EVP_sha1(),
    sha224 = C.EVP_sha224(),
    sha256 = C.EVP_sha256(),
    sha384 = C.EVP_sha384(),
    sha512 = C.EVP_sha512()
}

local buf = ffi_new("unsigned char[64]")


function _M.new(self, key, _hash)
    local ctx = ffi_new(ctx_ptr_type)
    
    C.HMAC_CTX_init(ctx)
    local md = _hash or hash.md5

    if C.HMAC_Init_ex(ctx, key, #key, md, nil) == 0 then
        return nil
    end
    return setmetatable({ _ctx = ctx }, mt)
end

function _M.update(self, s)
    return C.HMAC_Update(self._ctx, s, #s) == 1
end


function _M.final(self)
    local out_len = ffi_new("unsigned int[1]")

    if C.HMAC_Final(self._ctx, buf, out_len) == 1 then
        return ffi_str(buf, out_len[0])
    end
    
    return nil
end


function _M.reset(self)
    C.HMAC_Init_ex(self._ctx, nil, 0, nil, nil)
end

function _M.cleanup(self)
    C.HMAC_CTX_cleanup(self._ctx)
end

local class_mt = {
    -- to prevent use of casual module global variables
    __newindex = function (table, key, val)
        error('attempt to write to undeclared variable "' .. key .. '"')
    end
}

return setmetatable(_M, class_mt)
