import { useEffect, useId, useState } from 'react'
import { USER } from "../../utils/Storage";
import { useNavigate } from "react-router-dom";
import { api } from '../../utils/Api'
import React from 'react'
import { Header } from './Header'

interface UserInfo {
    id: number,
    login: string,
    password: string,
    firstName: string,
    lastName: string,
    patronymic: string,
    mail: string,
    passport: string,
    amount: number,
    currency: string
}

export const Home = () => {
    const [authorized, isAuthorized] = useState(false)
    const [versionText, setVersion] = useState('')
    const [userInfo, setUserInfo] = useState<UserInfo | undefined>(undefined)

    const navigate = useNavigate()

    const requestOptions: RequestInit = {
        method: 'GET',
        headers: new Headers({
            'Content-Type': 'application/json'
        }),
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
                .then(d => { console.log({ fetchVersion: d }); return d.json() })
                .then(r => {
                    setVersion(r)
                })
            fetch(api.userInfo, requestOptions)            
                .then((response) => {
                    if (!response.ok) throw new Error(response.status.toString());
                    else return response.json();
                })
                .then((data) => {
                    console.log({body: data})
                    setUserInfo(data)
                })
                .catch((error) => {
                    console.log(error + " in registration")
                    // setError({ enable: true, text: 'Попробуйте ввести другой логин или повторить попытку регистрации позднее' })
                })
        }
    }

    useEffect(() => {
        if (!authorized) {
            checkUser()
        }
    }
    );

    function historyItem(str: string): JSX.Element {
        return <div style={{ margin: 10 }} >
            <span>{str}</span>
        </div>
    }


    return (
        <div>
            <Header />
            <div className={"container md-6"} >
                <h1>Home</h1>
                {
                    userInfo ? <>
                        <p>Почта: {userInfo.mail}</p>
                        <p>Логин: {userInfo.login}</p>
                        <p>Сумма средст: {userInfo.amount}</p>
                    </> : <></>
                }
                <br></br>
                <label>История посещений</label>
                {historyItem("2002 info")}
                {historyItem("2003 info yandex")}
                {historyItem("2004 info honor 10")}

                <p>api: v: {versionText}</p>
            </div>
        </div>
    )
}