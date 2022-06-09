// export const server = "http://servermvp.ru:49379/"
export const server = "http://localhost:8080/"


export const api = {
	server: server,
    registration: `${server}account/registration`,
	authentication: `${server}hello`,
	authorization: `${server}login`,
	logout: `${server}logout`,
	version: `${server}account/version`,
	userInfo: `${server}account/info`,
	financialProduct: `${server}financial_product`,
	financialProductClose: `${server}financial_product/close`,
	financialProductStatus: `${server}financial_product/status`,
}