try {
    & w32tm /config /manualpeerlist:"time.windows.com" /syncfromflags:manual /reliable:YES /update
    & w32tm /resync
}
catch {
    throw "[Error] Couldn't sync time against time.windows.com!"
}