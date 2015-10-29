# Access Layer

The access layer is developed based on OpenResty. It is consist of 3 main features:

1.  Request limitation using [Token Bucket](https://en.wikipedia.org/wiki/Token_bucket), 
2.  Access Token validation for Http Request base on lua shared dict
3.  Signature validation for Http Request. I just wrapped a hmac lua lib base on openssl


The code style and inspiration mainly stem from [ABTestingGateway](https://github.com/SinaMSRE/ABTestingGateway) and [lua-resty-limit-traffic](https://github.com/openresty/lua-resty-limit-traffic)


