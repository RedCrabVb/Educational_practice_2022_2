import React, { useEffect, useState } from "react"
import { api } from '../utils/Api'
import { getItem } from '../utils/OperationItem'
import { ErrorView } from '../component/ErrorView'
import { Header } from "./commons/Header"
import { NOTE } from "../utils/Storage"
import { styleBlockItem, styleContainerItem, styleItems} from './commons/css/item'
import { Note } from '../component/class/Note'
import CSS from 'csstype'

export const Transactions = () => {


    function finacialProdcutItem(str: string): JSX.Element {
        return <div style={{margin: 10}} >
            <span>{str}</span>
            <button>info</button>
        </div>
    }

    return (
        <>
            <Header />
            {/* <ErrorView text={"error.text"}} /> */}
            <div className="container" style={style}>
                {finacialProdcutItem("9849585495 date")}
                {finacialProdcutItem("3948938543 date")}
                {finacialProdcutItem("349583958934 date")}
                <button>Create transactions</button>
                <label>Type transactions</label>
                <label>Sum</label>
                <input type="text"></input>
                <label>Currency</label>
                <input type="text"></input>
                <button>Send</button>
            </div>
        </>
    )
}

const style: CSS.Properties  = {
    display: 'inline-grid',
    flexDirection: 'row'
}