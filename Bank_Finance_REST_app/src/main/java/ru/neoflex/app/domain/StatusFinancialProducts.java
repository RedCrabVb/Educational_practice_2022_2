package ru.neoflex.app.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.Date;


@Entity
@Table(name = "t_status_financial_products")
@Getter
@Setter
@NoArgsConstructor
public class StatusFinancialProducts {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long statusFinancialProductsId;
    private User tUser;
    @ManyToOne
    private FinancialProducts financialProducts;
    private Date openDate;
    private Date closeDate;
}
