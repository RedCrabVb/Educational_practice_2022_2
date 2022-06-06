// export const server = "http://servermvp.ru:49379/"
export const server = "http://localhost:8080/"


export const api = {
	server: server,
    registration: `${server}account/registration`,
	authentication: `${server}hello`,
	authorization: `${server}login`,
	logout: `${server}logout`,
	version: `${server}account/version`,
	note: `${server}note`,
	saveNote: `${server}note/save`,
	saveSmartTask: `${server}smarttask/save`,
	smartTask: `${server}smarttask`,
	timerTracker: `${server}timertracker`,
	saveTimerTracker: `${server}timertracker/save`,
	userInfo: `${server}user_info`,
    disableTelegram: `${server}disable_tg`
}