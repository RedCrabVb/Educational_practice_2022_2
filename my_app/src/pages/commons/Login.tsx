import React, { useEffect, useState } from 'react'
import { USER } from "../../utils/Storage"
import { api } from '../../utils/Api'
import { useNavigate } from "react-router-dom"
import { ErrorView } from '../../component/ErrorView'
import { route } from "../../utils/ScreenNames"

export const LogIn = () => {
    const [username, setLogin] = useState('')
    const [password, setPasswordn] = useState('')

    const [error, setError] = React.useState({ enable: false, text: '' })
    const [errors, setErrors] = React.useState({ email: undefined, password: undefined })

    const navigate = useNavigate()

    const validate = async () => {
        console.log("handler aut isValid")

        let isValid = true
        if (username.length < 4) {
            handleError('Логин должен быть длиннее 4 символов', 'email')
            isValid = false
        } else {
            handleError(undefined, 'email')
        }
        if (password.length < 4) {
            handleError('Пароль должен быть длиннее 4 символов', 'password')
            isValid = false
        } else {
            handleError(undefined, 'password')
        }
        if (isValid) {
            handlerAut()
        }
    }

    const handleError = (error: string | undefined, input: string) => {
        setErrors(prevState => ({ ...prevState, [input]: error }));
    }

    const handlerAut = () => {

        const requestOptions: RequestInit = {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: `username=${username}&password=${password}`,
            credentials: 'include'
        }
        fetch(api.authorization, requestOptions)
            .then((response) => {
                if (!response.ok) {
                    throw new Error(response.status.toString())
                } else if (response.url.endsWith("login?error")) {
                    throw new Error("401")
                } else {
                    return response
                }
            })
            .then((data) => {
                localStorage.setItem(USER, "")
                navigate(route.home, { replace: true })
                console.log({ data })
                console.log("Yes, bay by")
            })
            .catch((error) => {
                if (error.message == 401) {
                    setError({ enable: true, text: 'Не верный логин или пароль' })
                } else {
                    console.log(error + " in login")
                }
            })
    }

    function ErrorSpan({ text }: { text: string | undefined }) {
        return (
            text != null ? <span className="containerError mb-3">{text}</span> : <br></br>
        )
    }

    function elementInput(value: string, setValue: (f: string) => void, name: string, error_text: string | undefined, type: string = 'text') {
        return (
            <div className="mb-3">
                <label className="form-label">{name}</label>
                <ErrorSpan text={error_text} />
                <input type={type} className="form-control" id="username"
                    value={value} onChange={(e) => setValue(e.target.value)} />
            </div>
        )
    }

    return (
        <div className="containerForm col-md-4 border">

            <div className="col-md-10">
                <ErrorView text={error.text} enable={error.enable} />
                {elementInput(username, setLogin, 'Логин', errors.email)}
                {elementInput(password, setPasswordn, 'Пароль', errors.password, 'password')}

                <div className="mb-3">
                    <button onClick={validate} className="btn btn-primary mb-3 customButtons">Войти</button>
                    <button onClick={() => { navigate(route.registration, { replace: true }) }} className="btn btn-primary customButtons">Регистрация</button>
                </div>
            </div>

        </div>
    )
}