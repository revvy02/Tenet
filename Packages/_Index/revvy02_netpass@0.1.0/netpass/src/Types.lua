--[=[
    @type NetData (table | boolean | string | number | Instance)?
    @within NetPass
]=]
export type NetData = (table | boolean | string | number | Instance)?

--[=[
    @type PairData {k: NetData, v: NetData, d: KeyData}
    @within NetPass
]=]
export type PairData = {
    k: NetData,
    v: NetData,
    d: KeyData
}

--[=[
    @type KeyData {PairData}
    @within NetPass
]=]
export type KeyData = {
    PairData
}

--[=[
    @type MetaData {KeyData?}?
    @within NetPass
]=]
export type MetaData = {
    KeyData?
}?

return nil