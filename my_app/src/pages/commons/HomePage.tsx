import { useEffect, useId, useState } from 'react'
import { USER } from "../../utils/Storage";
import { useNavigate } from "react-router-dom";
import { api } from '../../utils/Api'
import React from 'react'
import { Header } from './Header'

interface UserInfo {
    email: string;
    username: string;
    chatIdTg: string | null;
    confirmedTg: boolean;
    secretTokenTg: string | null;
}

export const Home = () => {
    const [authorized, isAuthorized] = useState(false)
    const [versionText, setVersion] = useState('')
    const [userInfo, setUserInfo] = useState<UserInfo | undefined>(undefined)

    const navigate = useNavigate()

    const requestOptions: RequestInit = {
        method: 'GET',
        headers: new Headers({ }),
        credentials: 'include',
    }

    function checkUser() {

        const userInfo = localStorage.getItem(USER)

        if (userInfo == null) {
            navigate("login", { replace: true })
        } else {
            console.log({ userInfo })
            isAuthorized(true)
            fetch(api.version, requestOptions)
                .then(d => { console.log({fetchVersion: d}); return d.json() })
                .then(r => {
                    setVersion(r)
                })
            // fetch(api.userInfo, requestOptions)
            //     .then(d => d.json())
            //     .then(r => {
            //         console.log(r)
            //         setUserInfo(r)
            //     })
        }
    }

    function botDisable(e: any) {
        const data: string = localStorage.getItem(USER) || 'null'

        console.log(JSON.stringify(userInfo))

        const requestOptions = {
            method: 'POST',
            headers: new Headers(
                {
                    'Content-Type': 'application/json',
                    'Authorization': data.toString(),
                }
            ),
        }

        // fetch(api.disableTelegram, requestOptions)
        //     .then(d => d.json())
        //     .then(r => {
        //         console.log(r)
        //         setUserInfo(r)
        //     })
    }

    useEffect(() => {
        if (!authorized) {
            checkUser()
        }
    }
    );


    return (
        <div>
            <Header />
            <div className={"container md-6"} >
                <h1>Home</h1>
                {
                    userInfo ? <>
                        <p>Почта: {userInfo.email}</p>
                        <p>Логин: {userInfo.username}</p>
                        {userInfo.secretTokenTg != null && !userInfo.confirmedTg ?
                            <p>Код для подписки бота: {userInfo.secretTokenTg}</p>
                            : <></>
                        }

                        <p>Оповещения в телеграмме {!userInfo.confirmedTg ? <span>не</span> : <></>} активированы</p>
                        {userInfo.confirmedTg ? <button className={"btn btn-info"} onClick={botDisable}>Отписка от бота</button> : <></>}
                    </> : <></>
                }
                <br></br>
                <a href={"https://t.me/note_30_05_bot"}>Telegram bot</a>

                <p>api: v: {versionText}</p>
            </div>
        </div>
    )
}