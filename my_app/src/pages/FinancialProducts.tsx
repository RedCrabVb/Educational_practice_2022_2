import React, { useEffect, useState } from "react"
import { Header } from "./commons/Header"
import CSS from 'csstype'

export const FinacialProducts = () => {


    function finacialProdcutItem(str: string): JSX.Element {
        return <div style={{margin: 10}} >
            <span>{str}</span>
            <button>close</button>
        </div>
    }

    return (
        <>
            <Header />
            {/* <ErrorView text={"error.text"}} /> */}
            <div className="container" style={style}>
                {finacialProdcutItem("fsd")}
                {finacialProdcutItem("asdf")}
                {finacialProdcutItem("finacialProducts")}
                <button>Open</button>
                <label>Prouct name</label>
                <input type="text"></input>
                <label>Date open</label>
                <input type="date"></input>
                <label>Date close</label>
                <input type="date"></input>
                <button>Save</button>
            </div>
        </>
    )
}

const style: CSS.Properties  = {
    display: 'inline-grid',
    flexDirection: 'row'
}