import React, { useEffect, useState } from "react"
import { Header } from "./commons/Header"
import CSS from 'csstype'
import { getItem } from "../utils/OperationItem"
import { Item } from "../component/class/Item"
import { api } from "../utils/Api"
import { stor } from "../utils/Storage"
import { Dropdown } from "react-bootstrap"
import { ErrorView } from "../component/ErrorView"

interface TypeTransactions {
    typeTransactionsId: number
    name: string
}

interface AccountTransactions extends Item {
    accountTransactionsId: number
    amount: number
    currency: string
    date: Date
    typeTransactions: TypeTransactions
}

export const Transactions = () => {
    const [createTransactions, setCreateTransactions] = useState(false)
    const [allTransactions, setAllTransactions] = useState<Array<AccountTransactions>>([])
    const [currency, setcurrency] = useState("RUB")
    const [amount, setAmount] = useState(0)
    const [transferAccount, setTransferAccount] = useState<string | undefined>(undefined)

    const [minDate, setMinDate] = useState<Date>(new Date(new Date().getTime() - (1000 * 60 * 60 * 24)))
    const [maxDate, setMaxDate] = useState<Date>(new Date())

    const [error, setError] = useState({ enable: false, text: '' })

    const [isLoading, setIsLoading] = useState(false)


    function AccountTransactionsItem({ item }: { item: AccountTransactions }): JSX.Element {
        return (
            <div className={item.typeTransactions.typeTransactionsId == 1 ? "p-3 mb-2 bg-danger text-white" : "p-3 mb-2 bg-success text-white"}><p>{item.amount} {item.currency}</p><p>{new Date(item.date).toISOString()}</p></div>
        )
    }


    useEffect(() => {
        if (!isLoading) {
            setIsLoading(true)
            getItem(setAllTransactions, setError, api.transactions, stor.TYPE_TRANSACTIONS)
        }
    })

    function makeTransactions() {

        const requestOptions: RequestInit = {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ currency, amount, transferAccount }),
            credentials: 'include'
        }
        fetch(api.transactions, requestOptions)
            .then((response) => {
                if (!response.ok) throw new Error(response.status.toString());
                else return response.json();
            })
            .then((data) => {
                console.log(data)
                setAllTransactions([data, ...allTransactions])
            })
            .catch((error) => {
                console.log(error + " in open product")
                setError({ enable: true, text: 'Попробуйте открыть финансовый продукт позже' })
            })
    }

    return (

        <>
            <Header />
            <div className="container" style={style}>
                <ErrorView text={error.text} enable={error.enable} />


                <div className="row row-cols-1 m-4 border border-5" style={{ margin: '10%', padding: 20 }}>
                    <button onClick={() => { setCreateTransactions(!createTransactions) }} className={createTransactions ? "btn btn-primary" : "btn btn-secondary"}>Совершить транзакцию</button>
                    {
                        createTransactions && <>
                            <label>Счет</label>
                            <input type="text" placeholder="логин пользователя" defaultValue={transferAccount} onChange={(e) => setTransferAccount(e.target.value)}></input>
                            <label>Сумма средст</label>
                            <input type="number" defaultValue={amount} onChange={(e) => setAmount(Number(e.target.value))}></input>
                            <label>Валюта</label>
                            <input disabled={true} type="text" defaultValue={"RUB"}></input>
                            <label>Итог</label>
                            <button className={"btn btn-secondary"} onClick={makeTransactions} >Отправить</button>
                        </>
                    }
                </div>

                <div className="row row-cols-1 m-4">
                    <label>История транзакций</label>
                    <label>От </label>
                    <input type="date" defaultValue={minDate.toISOString().substr(0,10)} onChange={(e) => setMinDate(new Date(e.target.value))}></input>

                    <label>До</label>
                    <input type="date" defaultValue={maxDate.toISOString().substr(0,10)} onChange={(e) => setMaxDate(new Date(e.target.value))}></input>

                </div>

                <div className="row row-cols-1 m-4">
                    {allTransactions
                        .sort((s, s1) => {
                            return new Date(s1.date).getTime() - new Date(s.date).getTime()
                        })
                        .filter(f => new Date(f.date) > minDate && new Date(f.date) < maxDate)
                        .map(fp => <AccountTransactionsItem key={fp.accountTransactionsId} item={fp}></AccountTransactionsItem>)}
                </div>

            </div>
        </>
    )
}

const style: CSS.Properties = {
    flexDirection: 'row'
}