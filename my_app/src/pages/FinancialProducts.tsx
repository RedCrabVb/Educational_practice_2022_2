import React, { useEffect, useState } from "react"
import { Header } from "./commons/Header"
import CSS from 'csstype'
import { getItem } from "../utils/OperationItem"
import { Item } from "../component/class/Item"
import { api } from "../utils/Api"
import { stor } from "../utils/Storage"
import { Dropdown } from "react-bootstrap"
import { ErrorView } from "../component/ErrorView"

interface FinacialProducts extends Item {
    financialProductsId: number
    title: string
    description: string
}

interface StatusFinancialProductsItem extends Item {
    statusFinancialProductsId: number
    financialProducts: FinacialProducts
    openDate: Date
    closeDate: Date
}

export const FinacialProducts = () => {
    const [financialProductOpen, setFinancialProductOpen] = useState(false)
    const [financialProductAll, setFinancialProductsAll] = useState<Array<FinacialProducts>>([])
    const [financialProductStatusAll, setFinancialProductStatusAll] = useState<Array<StatusFinancialProductsItem>>([])

    const [selectProductId, setSelectProductId] = useState(-1)
    const [dateOpen, setDateOpen] = useState(new Date())
    const [dateClose, setDateClose] = useState(new Date())

    const [error, setError] = useState({ enable: false, text: '' })

    const [isLoading, setIsLoading] = useState(false)


    function FinacialProdcutItem({ item }: { item: StatusFinancialProductsItem }): JSX.Element {
        return <div style={{ margin: 10 }} className="btn btn-outline-secondary" >
            <span>{item.financialProducts.title}</span>
            <br></br>
            <><span>{item.openDate && new Date(item.openDate).toLocaleDateString()}</span>-<p>{item.openDate && new Date(item.closeDate).toLocaleDateString()}</p></>
            <button className="btn btn-danger" onClick={() => closePorduct(item)}>close</button>
        </div>
    }


    const onChangeStatus = ( e: React.ChangeEvent<HTMLInputElement>) => {
        setDateClose(new Date(e.target.value))
    }

    function FinacialProdcutItemDrop({ item }: { item: FinacialProducts }): JSX.Element {
        return <Dropdown.Item onClick={() => { setSelectProductId(item.financialProductsId) }}>{item.title}</Dropdown.Item>
    }

    useEffect(() => {
        if (!isLoading) {
            setIsLoading(true)
            getItem(setFinancialProductsAll, setError, api.financialProduct, stor.FINACIAL_PRODCUT)
            getItem(setFinancialProductStatusAll, setError, api.financialProductStatus, stor.FINACIAL_PRODCUT_STATUS)
        }
    })

    function closePorduct(item: StatusFinancialProductsItem) {
        const requestOptions: RequestInit = {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: item.statusFinancialProductsId.toString(),
            credentials: 'include'
        }
        console.log(requestOptions.body)
        fetch(api.financialProductClose, requestOptions)
            .then((response) => {
                if (!response.ok) throw new Error(response.status.toString());
                else return response.json();
            })
            .then((data) => {
                console.log(data)
                setFinancialProductStatusAll(financialProductStatusAll.filter(f => 
                    f.statusFinancialProductsId != item.statusFinancialProductsId))
            })
            .catch((error) => {
                console.log(error + " in open product")
                setError({ enable: true, text: 'Попробуйте открыть финансовый продукт позже' })
            })
    }

    function openProduct() {
        const statusFinancialProductsTmp = {financialProductsId: selectProductId, openDate: dateOpen, closeDate: dateClose}

        const requestOptions: RequestInit = {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(statusFinancialProductsTmp),
            credentials: 'include'
        }
        console.log(requestOptions.body)
        fetch(api.financialProduct, requestOptions)
            .then((response) => {
                if (!response.ok) throw new Error(response.status.toString());
                else return response.json();
            })
            .then((data) => {
                console.log(data)
                setFinancialProductStatusAll([data, ... financialProductStatusAll])
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


                <div className="row row-cols-1 m-4 border border-5" style={{ margin: '10%', padding: 20}}>
                    <button onClick={() => { setFinancialProductOpen(!financialProductOpen) }} className={financialProductOpen ? "btn btn-primary" : "btn btn-secondary"}>Открыть финансовый продукт</button>
                    {
                        financialProductOpen && <>
                            <label>Название продукта</label>
                            <Dropdown>
                                <Dropdown.Toggle variant="success" id="dropdown-basic">
                                    {selectProductId != -1 ? financialProductAll.filter(f => f.financialProductsId == selectProductId)[0].title : 'Выбрать'}
                                </Dropdown.Toggle>

                                <Dropdown.Menu>
                                    {financialProductAll.map(fp => <FinacialProdcutItemDrop key={fp.financialProductsId} item={fp}></FinacialProdcutItemDrop>)}
                                </Dropdown.Menu>
                            </Dropdown>
                            <label>Дата открытия</label>
                            <input disabled={true} type="text" defaultValue={dateOpen.toLocaleDateString()}></input>
                            <label>Дата закрытия</label>
                            <input type="date" onChange={onChangeStatus}></input>
                            <label>Итог</label>
                            <button className={"btn btn-secondary"} onClick={openProduct}>Сохранить</button>
                        </>
                    }
                </div>

                <div className="row row-cols-1 m-4">
                    {financialProductStatusAll
                    .filter(f => f.closeDate && new Date(f.closeDate).getTime() >= new Date().getTime())
                    .map(fp => <FinacialProdcutItem key={fp.statusFinancialProductsId} item={fp}></FinacialProdcutItem>)}
                </div>

            </div>
        </>
    )
}

const style: CSS.Properties = {
    display: 'inline-grid',
    flexDirection: 'row'
}